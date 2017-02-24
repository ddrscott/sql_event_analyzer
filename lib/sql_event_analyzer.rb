require 'sql_event_analyzer/version'
require 'active_support/notifications'
require 'active_record'

# Captures Rails SQL events and crunches some statistics
class SqlEventAnalyzer

  attr_reader :stats, :name

  # captures the events and writes out the result
  # @return [File] file containing html output
  def self.start(name: Time.current)
    instance = SqlEventAnalyzer.new(name: name)

    subscription_name = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      instance.process_event(event)
    end

    if block_given?
      begin
        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(subscription_name)
      end
      write_html(instance)
    end
  end

  def self.write_html(instance)
    output_dir = 'tmp/sql_event_analyzer'
    output_path = File.join(output_dir, "#{instance.name}.html")
    FileUtils.mkdir_p(output_dir)
    html = instance.render_as_html
    File.open(output_path, 'w') {|f| f << html}
  end

  def initialize(name:)
    @name = name
    @root = Rails.root.to_s
    @stats = {}
  end

  # @param [ActiveSupport::Notifications::Event] SQL event from Rails
  def process_event(event)
    # Callers from Rails root and not the subscriber itself
    backtrace = caller.select{|line| relevent_caller?(line) }

    # Initialize a uniq SQL use.
    # `:payload` will always be the first instance of the call.
    stat = @stats[backtrace] ||= {
      order: @stats.size,
      count: 0,
      duration: 0,
      payload: event.payload
    }

    # increment stats
    stat[:count] += 1
    stat[:duration] += event.duration
  end

  def render_as_html
    ERB.new(erb_template).result(binding)
  end

  private

  def relevent_caller?(c)
    c.start_with?(@root) && !c.start_with?(__FILE__)
  end

  def pretty_sql(sql)
    sql
      .delete('"')
      .gsub(/\b+(SELECT|FROM|WHERE|GROUP|HAVING|LEFT JOIN|LEFT OUTER JOIN|INNER JOIN|JOIN|RIGHT|ORDER|WINDOW)\b+/, "\n\\1")
  end

  def explain(payload)
    ActiveRecord::Base.connection.explain(payload[:sql], payload[:binds])
  end

  def erb_template
    File.read(File.join(__dir__, 'sql_event_analyzer.erb'))
  end

  def trim_caller(c)
    c.gsub(@root, '.')
  end

  def debug_rb(c)
    first = trim_caller(c)
    file, line = if first =~ /(.*\.rb):(\d+)/
                   [$1, $2]
                 end
    rb_src = File.readlines(file)[line.to_i - 1].strip
    <<-EOF.strip_heredoc
    -- #{first}
    --     #{rb_src}
    EOF
  end
end

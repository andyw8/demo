class CLIChannel < ApplicationCable::Channel
  class CLI < Thor
    class BlogCLI < Thor
      desc "list", "Lists all blogs"
      def list
        Blog.find_each.map { |blog| "#{blog.id}: #{blog.title}" }
      end

      desc "create TITLE", "Creates a new blog with the given title"
      def create(title)
        blog = Blog.create(title: title)
        "Created blog: #{blog.id}: #{blog.title}"
      end

      desc "rm ID", "Deletes the blog with the given ID"
      def rm(id)
        blog = Blog.find_by(id: id)
        if blog
          blog.destroy
          "Deleted blog: #{id}: #{blog.title}"
        else
          "Blog not found with ID: #{id}"
        end
      end
    end

    desc "blogs SUBCOMMAND ...ARGS", "Manage blogs"
    subcommand "blogs", BlogCLI
  end

  def subscribed
    stream_from "cli_channel"
  end

  def receive(data)
    command = data['command']
    args = data['args'] || []

    output = StringIO.new

    begin
      $stdout = output
      $stderr = output

      result = CLI.start([command] + args)
      output.puts(result) if result.is_a?(Array) || result.is_a?(String)
    ensure
      $stdout = STDOUT
      $stderr = STDERR
    end

    transmit({ output: output.string })
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
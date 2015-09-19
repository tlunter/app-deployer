module AppDeployer
  module Core
    class Executor
      def self.local(*args)
        LocalExecutor.new(*args)
      end

      def self.remote(*args)
        RemoteExecutor.new(*args)
      end

      def initialize
        raise 'Do not initialize Executor! Use LocalExecutor or RemoteExecutor instead'
      end

      def kill(process_id:, signal: nil, &block)
        cmd = ['kill']
        cmd << "-#{signal}" if signal
        cmd << "#{process_id}"
        run(cmd, &block)
      end

      def print_file(file_name:)
        cmd = ['cat', "#{file_name}"]
        output = StringIO.new
        exitstatus = run(cmd) { |line| output << line }

        raise "Could not read file: `#{output.string.chomp}`" unless exitstatus.zero?

        output.string
      end

      def write_file(file_name:, contents:, append: false, &block)
        cmd = ['tee']
        cmd << '-a' if append
        cmd << "#{file_name}"
        run(cmd, stdin: contents, &block)
      end
    end

    class LocalExecutor < Executor
      def initialize
      end

      def run(cmd, stdin: nil)
        $stderr.puts "Running #{cmd}"

        mode = stdin ? 'r+' : 'r'
        IO.popen(cmd, mode, err: [:child, :out]) do |io|
          if stdin
            if stdin.respond_to?(:read)
              io.write(stdin.read)
            else
              io.write(stdin)
            end
            io.close_write
          end

          begin
            while line = io.readline
              if block_given?
                yield line
              else
                $stderr.puts line
              end
            end
          rescue EOFError
            nil
          end
        end

        exitstatus = $?.exitstatus

        $stderr.puts "Command `#{cmd}` exited: #{exitstatus}"

        exitstatus
      end
    end

    class RemoteExecutor < Executor
      attr_reader :ssh_config

      def initialize(ssh_config:)
        @ssh_config = ssh_config
      end

      def run(cmd, stdin: nil)
        exitstatus = nil

        $stderr.puts "Running #{cmd}"

        Net::SSH.start(ssh_config[:host], ssh_config[:user]) do |ssh|
          ssh.open_channel do |ch|
            ch.exec(cmd.join(' ')) do |_, success|
              ch.on_data do |_, data|
                if block_given?
                  yield data
                else
                  $stderr.puts data
                end
              end

              ch.on_extended_data do |_, _, data|
                if block_given?
                  yield data
                else
                  $stderr.puts data
                end
              end

              ch.on_request('exit-status') do |_, data|
                exitstatus = data.read_long
              end

              if stdin
                if stdin.respond_to?(:read)
                  ch.send_data(stdin.read)
                else
                  ch.send_data(stdin)
                end
                ch.eof!
              end
            end
          end
        end

        $stderr.puts "Command `#{cmd}` exited: #{exitstatus}"

        exitstatus
      end
    end
  end
end

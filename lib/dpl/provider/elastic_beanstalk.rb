module DPL
  class Provider
    class ElasticBeanstalk < Provider
      experimental 'AWS Elastic Beanstalk'
      
      CLI_ZIP_URL = 'https://s3.amazonaws.com/elasticbeanstalk/cli/AWS-ElasticBeanstalk-CLI-2.6.1.zip'
      
      STACKS = {
        "php_32" => "32bit Amazon Linux running PHP 5.3",
        "php" => "64bit Amazon Linux running PHP 5.3",
        "node_32" => "32bit Amazon Linux running Node.js",
        "node" => "64bit Amazon Linux running Node.js",
        "python_32" => "32bit Amazon Linux running Python",
        "python" => "64bit Amazon Linux running Python",
        "ruby" => "64bit Amazon Linux 2014.03 v1.0.1 running Ruby 2.0 (Puma)",
        "ruby_passenger" => "64bit Amazon Linux 2014.03 v1.0.1 running Ruby 2.0 (Passenger Standalone)",
        "docker" => "64bit Amazon Linux 2014.03 v1.0.3 running Docker 0.9.0"
      }
      
      def needs_key?
        false
      end
      
      def environment
        options[:environment] || option(:application) + "-production"
      end
      
      def tier
        tier_name = options[:tier] || "web_server"
        {"web_server" => "1", "worker" => "2"}[tier_name.to_s]
      end
      
      def stack
        STACKS[option(:stack)]
      end
      
      def environment_type
        type_name = options[:environment_type] || 'load_balanced'
        {
          "load_balanced" => "1",
          "single_instance" => "2"
        }[type_name]
      end
      
      def install_cli_tools
        context.shell "wget #{CLI_ZIP_URL} -O .dpl/eb-cli.zip"
        context.shell "unzip .dpl/eb-cli.zip -d .dpl"
        context.shell "export PATH=$PATH:$PWD/.dpl/AWS-ElasticBeanstalk-CLI-2.6.1/eb/linux/python2.7"
      end

      def push_app
        log "Pushing current branch to '#{environment}' environment"
        context.shell "git aws.push --environment #{environment}"
      end
      
      def check_auth
        install_cli_tools
        log "Configuring Elastic Beanstalk CLI tool"
        File.open('.dpl/input.txt', 'w'){|f| f.write(
          [option(:access_key_id), option(:secret_access_key), option(:application), environment, tier, environment_type, "n", "y"].join("\n")
        )}
        context.shell "eb init -I #{option(:access_key_id)} -S #{option(:secret_access_key)} -a #{option(:application)} -e #{environment} --region \"#{options[:region] || 'us-east-1'}\" -s \"#{stack}\" < .dpl/input.txt"
      end
    end
  end
end
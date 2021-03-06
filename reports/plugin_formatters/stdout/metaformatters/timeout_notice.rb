=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports

class Stdout
module PluginFormatters

class MetaModules
module MetaFormatters

    #
    # Stdout formatter for the results of the TimeoutNotice metamodule
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class TimeoutNotice < Arachni::Plugin::Formatter

        def initialize( metadata )
            @results     = metadata[:results]
            @description = metadata[:description]
        end

        def run
            print_status( ' --- Timeout notice:' )
            print_info( 'Description: ' + @description )

            print_line
            print_info( 'Relevant issues:' )
            print_info( '--------------------' )
            @results.each {
                |issue|
                print_ok( "[\##{issue['index']}] #{issue['name']} at #{issue['url']} in #{issue['elem']} variable '#{issue['var']}' using #{issue['method']}." )
            }
        end

    end

end
end
end
end
end
end

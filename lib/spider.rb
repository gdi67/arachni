=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'anemone'
require Arachni::Options.instance.dir['lib'] + 'module/utilities'

module Arachni

#
# Spider class
#
# Crawls the URL in opts[:url] and grabs the HTML code and headers.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Spider

    include Arachni::UI::Output
    include Arachni::Module::Utilities

    #
    #
    # @return [Options]
    #
    attr_reader :opts

    attr_reader :pages

    #
    # Sitemap, array of links
    #
    # @return [Array]
    #
    attr_reader :sitemap

    #
    # Code block to be executed on each page
    #
    # @return [Proc]
    #
    attr_reader :on_every_page_blocks

    #
    # Constructor <br/>
    # Instantiates Spider class with user options.
    #
    # @param  [Options] opts
    #
    def initialize( opts )
        @opts = opts

        @anemone_opts = {
            :threads              =>  1,
            :discard_page_bodies  =>  false,
            :delay                =>  0,
            :obey_robots_txt      =>  false,
            :depth_limit          =>  false,
            :link_count_limit     =>  false,
            :redirect_limit       =>  false,
            :storage              =>  nil,
            :cookies              =>  nil,
            :accept_cookies       =>  true,
            :proxy_addr           =>  nil,
            :proxy_port           =>  nil,
            :proxy_user           =>  nil,
            :proxy_pass           =>  nil
        }

        hash_opts = @opts.to_h
        @anemone_opts.each_pair {
            |k, v|
            @anemone_opts[k] = hash_opts[k.to_s] if hash_opts[k.to_s]
        }

        @anemone_opts = @anemone_opts.merge( hash_opts )

        @sitemap = []
        @on_every_page_blocks = []

        # if we have no 'include' patterns create one that will match
        # everything, like '.*'
        @opts.include =[ Regexp.new( '.*' ) ] if @opts.include.empty?
    end

    #
    # Runs the Spider and passes parsed page to the block
    #
    # @param [Block] block
    #
    # @return [Arachni::Parser::Page]
    #
    def run( &block )
        return if @opts.link_count_limit == 0

        i = 1
        # start the crawl
        Anemone.crawl( @opts.url, @anemone_opts ) {
            |anemone|

            # apply 'exclude' patterns
            anemone.skip_links_like( @opts.exclude ) if @opts.exclude

            # apply 'include' patterns and grab matching pages
            # as they are discovered
            anemone.on_pages_like( @opts.include ) {
                |page|

                @pages = anemone.pages.keys || []

                url = url_sanitize( page.url.to_s )

                # something went kaboom, tell the user and skip the page
                if page.error
                    print_error( "[Error: " + (page.error.to_s) + "] " + url )
                    print_debug_backtrace( page.error )
                    next
                end

                # push the url in the sitemap
                @sitemap.push( url )

                print_line
                print_status( "[HTTP: #{page.code}] " + url )

                # call the block...if we have one
                if block
                    exception_jail{
                        new_page = Arachni::Parser.new( @opts,
                            Typhoeus::Response.new(
                                :effective_url => url,
                                :body          => page.body,
                                :headers_hash  => page.headers
                            )
                        ).run
                        new_page.code   = page.code
                        new_page.method = 'GET'
                        block.call( new_page.clone )
                    }
                end

                # run blocks specified later
                @on_every_page_blocks.each {
                    |block|
                    block.call( page )
                }

                # we don't need the HTML doc anymore
                page.discard_doc!( )

                # make sure we obey the link count limit and
                # return if we have exceeded it.
                if( @opts.link_count_limit &&
                    @opts.link_count_limit <= i )
                    return @sitemap.uniq
                end

                i+=1
            }
        }

        return @sitemap.uniq
    end

    #
    # Decodes URLs to reverse multiple encodes and removes NULL characters
    #
    def url_sanitize( url )

        while( url =~ /%/ )
            url = ( URI.decode( url ).to_s.unpack( 'A*' )[0] )
        end

        return url
    end


    #
    # Hook for further analysis of pages, statistics etc.
    #
    # @param [Proc] block code to be executed for every page
    #
    # @return [self]
    #
    def on_every_page( &block )
        @on_every_page_blocks.push( block )
        self
    end

end
end

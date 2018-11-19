# Homebrew has $HOMEBREW_ARTIFACT_DOMAIN which allows using a mirror for downloads:
# 
# https://docs.brew.sh/Manpage#environment
#
# but no easy way to create such a mirror. This command which creates a mirror from
# all core formulae downloads. Pop it in /usr/local/Homebrew/Library/Homebrew/cmd/
# with a `chmod +x` and run `brew mirror-artifacts`.

require "formula"

base_path = Pathname.new(ENV.fetch("HOMEBREW_ARTIFACT_PATH") { Dir.pwd })

ohai "Mirroring all formula downloads to: #{base_path}"
Formula.core_files.each do |fi|
  begin
    f = Formula[fi]
  rescue
    opoo "#{fi}: something went wrong:"
    puts $!.message, *$!.backtrace
    next
  end

  ohai "Mirroring #{f}"
  [f.downloader, *f.resources.map(&:downloader)].each do |downloader|
    if downloader.is_a? CurlDownloadStrategy
      uri = URI.parse(f.downloader.url)
      path = base_path.join(uri.host, uri.path.delete_prefix("/"))
      path.parent.mkpath
      begin
        curl_download f.downloader.url, to: path
      rescue
        opoo "#{fi}: something went wrong:"
        puts $!.message, *$!.backtrace
      end
    end
  end
end

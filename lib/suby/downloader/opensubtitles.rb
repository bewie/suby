module Suby
  # Based on https://github.com/byroot/ruby-osdb/blob/master/lib/osdb/server.rb
  class Downloader::OpenSubtitles < Downloader
    SITE = 'dl.opensubtitles.org'
    FORMAT = :gz
    XMLRPC_HOST = 'api.opensubtitles.org'
    XMLRPC_PATH = '/xml-rpc'
    SUBTITLE_TYPES = [:tvshow, :movie, :unknown]

    USERNAME = ''
    PASSWORD = ''
    LOGIN_LANGUAGE = 'eng'
    USER_AGENT = 'Suby v0.4'

    SEARCH_QUERIES_ORDER = [:hash, :name] #There is also search using imdbid but i dont think it usefull as it
                                          #returns subtitles for many different versions

    # OpenSubtitles needs ISO 639-22B language codes for subtitles search
    # See http://www.opensubtitles.org/addons/export_languages.php
    # and http://en.wikipedia.org/wiki/List_of_ISO_639-2_codes
    LANG_MAPPING = {
      ar: "ara", bg: "bul", bn: "ben", br: "bre", bs: "bos", ca: "cat", cs: "cze", da: "dan", de: "ger", el: "ell",
      en: "eng", eo: "epo", es: "spa", et: "est", eu: "baq", fa: "per", fi: "fin", fr: "fre", gl: "glg", he: "heb",
      hi: "hin", hr: "hrv", hu: "hun", hy: "arm", id: "ind", is: "ice", it: "ita", ja: "jpn", ka: "geo", kk: "kaz",
      km: "khm", ko: "kor", lb: "ltz", lt: "lit", lv: "lav", mk: "mac", mn: "mon", ms: "may", nl: "dut", no: "nor",
      oc: "oci", pb: "pob", pl: "pol", pt: "por", ro: "rum", ru: "rus", si: "sin", sk: "slo", sl: "slv", sq: "alb",
      sr: "scc", sv: "swe", sw: "swa", th: "tha", tl: "tgl", tr: "tur", uk: "ukr", ur: "urd", vi: "vie", zh: "chi"
    }
    LANG_MAPPING.default = 'all'

    def download_url
      SEARCH_QUERIES_ORDER.find(lambda { raise NotFoundError, "no subtitles available" }) do |type|
        puts if $verbose
        hash_info = search_subtitles(search_query(type))
        #puts ">> hash_info: #{hash_info}"
        if hash_info['data'].length != 0 and hash_info['data'].first['SubDownloadLink'] 
          puts ">>>Find it on #{type}" if $verbose
          @type = type
          return hash_info['data'].first['SubDownloadLink'] 
        else
          puts "<<< Not found by #{type}"
        end
      end
    end

    def search_subtitles(query)
      return {} unless query
      query = [query] unless query.kind_of? Array
      #puts ">>>token/query: #{token} / #{query}"
      xmlrpc.call('SearchSubtitles', token, query)
    end

    def token
      @token ||= login
    end

    def login
      response = xmlrpc.call('LogIn', USERNAME, PASSWORD, LOGIN_LANGUAGE, USER_AGENT)
      unless response['status'] == '200 OK'
        raise DownloaderError, "Failed to login with #{USERNAME}:#{PASSWORD}. " +
                               "Server return code: #{response['status']}"
      end
      response['token']
    end

    def search_query(type = :hash)
      return nil unless query = send("search_query_by_#{type}")
      #t = query.merge(sublanguageid: language(lang))
      #puts ">>> search_query_by_#{type} | #{lang} | " +  t.to_s
      query.merge(sublanguageid: language(lang))
    end

    def search_query_by_hash
      puts "hash: #{MovieHasher.compute_hash(file)}" if $verbose
      puts "size: #{file.size.to_s}" if $verbose
      { moviehash: MovieHasher.compute_hash(file), moviebytesize: file.size.to_s } if file.exist?
    end

    def search_query_by_name
      season && episode ? { query: show, season: season, episode: episode } : { query: file.base.to_s }
    end

    def search_query_by_imdbid
      { imdbid: imdbid } if imdbid
    end

    def language(lang)
      LANG_MAPPING[lang.to_sym]
    end

    def success_message
      "Found by #{@type}"
    end
  end
end

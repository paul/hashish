module Hashish
  class Status < ::String
    Code2Message = (
      {
        100 => "Continue",
        101 => "Switching Protocols",
        102 => "Processing",

        200 => "OK",
        201 => "Created",
        202 => "Accepted",
        203 => "Non-Authoritative Information",
        204 => "No Content",
        205 => "Reset Content",
        206 => "Partial Content",
        207 => "Multi-Status",
        226 => "IM Used",

        300 => "Multiple Choices",
        301 => "Moved Permanently",
        302 => "Found",
        303 => "See Other",
        304 => "Not Modified",
        305 => "Use Proxy",
        307 => "Temporary Redirect",

        400 => "Bad Request",
        401 => "Unauthorized",
        402 => "Payment Required",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        406 => "Not Acceptable",
        407 => "Proxy Authentication Required",
        408 => "Request Timeout",
        409 => "Conflict",
        410 => "Gone",
        411 => "Length Required",
        412 => "Precondition Failed",
        413 => "Request Entity Too Large",
        414 => "Request-URI Too Long",
        415 => "Unsupported Media Type",
        416 => "Requested Range Not Satisfiable",
        417 => "Expectation Failed",
        422 => "Unprocessable Entity",
        423 => "Locked",
        424 => "Failed Dependency",
        426 => "Upgrade Required",

        500 => "Internal Server Error",
        501 => "Not Implemented",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        504 => "Gateway Timeout",
        505 => "HTTP Version Not Supported",
        507 => "Insufficient Storage",
        510 => "Not Extended"
      }
    ) unless defined?(Code2Message)

    Symbol2Code = (
      Code2Message.inject(Hash.new) do |hash, (code, message)|
        sym = Hashish.underscore(message.gsub(/\s+/, "")).to_sym
        hash.update(sym => code)
      end
    ) unless defined?(Symbol2Code)

    Symbol2Code.each do |sym, code|
      module_eval <<-__
        def Status.#{ sym }()
          @#{ sym } ||= Status.for(:#{ sym })
        end
      __
    end

    attr :code
    attr :message
    attr :group

    def initialize(code, message)
      @code, @message = Integer(code), String(message)
      @group = (@code / 100) * 100
      replace("#{ @code } #{ @message }".strip)
    end

    Groups = ({
      100 => 'instruction',
      200 => 'success',
      300 => 'redirection',
      400 => 'client_error',
      500 => 'server_error'
    }) unless defined?(Groups)

    Groups.each do |code, group|
      module_eval <<-__
        def #{ group }?()
          #{ code } == @group
        end
      __
    end

    def Status.list
      @list ||= Symbol2Code.sort_by{|sym, code| code}.map{|sym, code| send(sym)}
    end

    def good?
      @group < 400
    end
    alias_method 'ok?', 'good?'

    def bad?
      @group >= 400
    end
    alias_method 'error?', 'bad?'

    def Status.for(*args)
      if args.size >= 2
        code = args.shift
        message = args.join(' ')
        new(code, message)
      else
        arg = args.shift
        case arg
          when Status
            arg
          when Fixnum
            code = arg
            message = Code2Message[code]
            new(code, message)
          when Symbol
            code = Symbol2Code[arg]
            if code
              message = Code2Message[code]
            else
              code = 500
              message = "Unknown Status #{ arg.inspect }"
            end
            new(code, message)
          else
            if arg.respond_to?(:code) and arg.respond_to?(:message)
              code, message = arg.code, arg.message
              new(code, message)
            else
              parse(arg)
            end
        end
      end
    end

    def Status.parse(string)
      first, last = string.to_s.strip.split(%r/\s+/, 2)
      if first =~ %r/^\d+$/
        code = Integer(first)
        message = last
      else
        code = 500
        message = "Unknown Status #{ string.inspect }"
      end
      new(code, message)
    end
  end

  def Hashish.status(*args, &block)
    if args.empty? and block.nil?
      Status
    else
      Status.for(*args, &block)
    end
  end
end

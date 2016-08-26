def simple_command(v, opts = {})
  Expeditor::Command.new(opts) do
    v
  end
end

def sleep_command(n, v, opts = {})
  Expeditor::Command.new(opts) do
    sleep n
    v
  end
end

def error_command(e, v, opts = {})
  Expeditor::Command.new(opts) do
    raise e
    v
  end
end

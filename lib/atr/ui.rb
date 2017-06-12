require "curses"
require "io/console"

# Not sure I need this:
#
# def onsig(sig)
#   Curses.close_screen
#   exit sig
# end

# for i in %w[HUP INT QUIT TERM]
#   if trap(i, "SIG_IGN") != 0 then  # 0 for SIG_IGN
#     trap(i) {|sig| onsig(sig) }
#   end
# end

module Atr
  module UI
    extend self

    def colorize(str, color)
      color_flag = "\033[" + color.to_s + "m"
      "#{color_flag}#{str}\033[0m"
    end

    def magenta(str)
      colorize(str, 36)
    end

    def green(str)
      colorize(str, 32)
    end

    def yellow(str)
      colorize(str, 33)
    end

    def print_usage
      puts
      puts " \u203A Press #{magenta('a')} to run all tests"
      puts " \u203A Press #{magenta('s')} to run subset of tests"
      puts " \u203A Press #{magenta('c')} to run changed tests"
      puts " \u203A Press #{magenta('f')} to run failed tests"
      puts " \u203A Press #{magenta('q')} to quit"
      puts " \u203A Press #{magenta('Enter')} to run the last command"
      puts
    end

    def print_welcome
      puts "Welcome to #{green('atr')}, interactive test runner"
    end

    CONTROL_KEYS = {
      "\x01" => :ctrl_a,
      "\x02" => :ctrl_b,
      "\x03" => :ctrl_c,
      "\x04" => :ctrl_d,
      "\x05" => :ctrl_e,
      "\x06" => :ctrl_f,
      "\a"   => :ctrl_g,
      "\b"   => :ctrl_h,
      "\t"   => :tab,   # aka CTRL+I
      "\n"   => :ctrl_n,
      "\v"   => :ctrl_k,
      "\f"   => :ctrl_l,
      "\r"   => :enter, # aka CTRL+M
      "\x0e" => :ctrl_n,
      "\x0f" => :ctrl_o,
      "\x10" => :ctrl_p,
      "\x11" => :ctrl_q,
      "\x12" => :ctrl_r,
      "\x13" => :ctrl_s,
      "\x14" => :ctrl_t,
      "\x15" => :ctrl_u,
      "\x16" => :ctrl_v,
      "\x17" => :ctrl_w,
      "\x18" => :ctrl_x,
      "\x19" => :ctrl_y,
      "\x1a" => :ctrl_z,
      "\e"   => :esc,
      "\x7f" => :backspace
    }

    def action_prompt
      loop do
        key = buffered_getch

        if event = CONTROL_KEYS[key]
          case event
          when :enter
            return :repeat
          when :ctrl_c
            terminate
          end
        else
          terminate if key == "q"
          action = key_to_event(key)
          return action if action
        end
      end
    end

    def terminate
      puts "Exiting..."
      Process.exit
    end

    def key_to_event(key)
      case key
      when "a"
        :all
      when "s"
        :subset
      when "c"
        :changes
      when "f"
        :failed
      end
    end

    def buffered_getch
      begin
        IO.console.raw!
        key = IO.console.getch

        if key == "\e"
          begin
            char = IO.console.getch(min: 0, time: 0)
            key += char unless char.nil?
          end until char.nil?
        end
        key
      ensure
        IO.console.cooked!
      end
    end

    def prompt(runnables)
      Curses.init_screen
      Curses.nl
      Curses.noecho
      Curses.cbreak

      print_candidates(runnables, total: runnables.size)

      candidates = runnables
      Curses.setpos(Curses.lines - 1, 0)
      prompt = "> "
      Curses.addstr(prompt)
      Curses.refresh

      query = ""
      while true
        Curses.setpos(Curses.lines - 1, prompt.size + query.size)

        char = Curses.getch
        case char
        when 127 # backspace
          if query.size > 0
            query = query[0..-2]
            Curses.setpos(Curses.lines - 1, prompt.size + query.size)
            Curses.clrtoeol
          end
        when 27 # ignore arrows
          next
        when 10 # enter
          Curses.close_screen
          return candidates
        else
          query << char.to_s
          Curses.addstr(char.to_s)
        end

        Curses.refresh

        pattern = Regexp.new(query)
        candidates = runnables.select { |n| n.name.to_s =~ pattern }

        print_candidates(candidates, total: runnables.size)
      end
    ensure
      Curses.close_screen
    end

    def print_candidates(candidates, total:)
      (Curses.lines - candidates.size - 2).times do |t|
        Curses.setpos(t, 0)
        Curses.clrtoeol
      end

      unique_label = candidates.all? { |c| c.suite == candidates.first.suite }
      candidates.each_with_index do |cand, index|
        Curses.setpos(Curses.lines - 2 - candidates.size + index, 0)
        Curses.clrtoeol
        if unique_label
          Curses.addstr(cand.name.to_s)
        else
          Curses.addstr("#{cand.suite}##{cand.name}")
        end
      end

      Curses.setpos(Curses.lines - 2, 0)
      Curses.clrtoeol
      Curses.addstr("#{candidates.size}/#{total}")
    end
  end
end

  # Record = Struct.new(:label)

  # runnables = [:test_single_iteration,
  #  :test_each_record_sets_shop_current_when_records_are_shops,
  #  :test_maintenance_task,
  #  :test_emits_interrupted_metric_when_resumed,
  #  :test_failing_job,
  #  :test_ignored_by_long_running_shitlist,
  #  :test_master_table,
  #  :test_each_record_method_missing,
  #  :test_build_enumerable_method_missing,
  #  :test_plain_enumerable,
  #  :test_passes_params_to_each_record_without_extra_information_on_interruption,
  #  :test_cannot_override_perform,
  #  :test_batched_enumerable,
  #  :test_build_enumerable_returns_nil,
  #  :test_podded_batches_complete,
  #  :test_relation_with_limit,
  #  :test_shops,
  #  :test_passes_params_to_each_record,
  #  :test_emits_interrupted_metric_when_interrupted,
  #  :test_works_with_private_methods,
  #  :test_build_enumerable_returns_array_of_activerecord,
  #  :test_podded,
  #  :test_reports_each_record_runtime,
  #  :test_multiple_columns,
  #  :test_podded_batches,
  #  :test_iteration_options_method_missing,
  #  :test_relation_with_order].map(&:to_s).map { |n| Record.new(n) }

  # UI.prompt(runnables)

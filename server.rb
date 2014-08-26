require 'sinatra'


post '/stock_prices' do
  symbol = params[:symbol]
  validate_symbol(symbol)

  analyzer = StockAnalyzer.new

  request.body.each_line do |line|
    price_point = PricePoint.parse(line)
    analyzer.add(price_point)
  end

  result = "#{symbol},#{analyzer.buy_point.time.to_i},#{analyzer.sell_point.time.to_i}"
  logger.info(result)
  result
end

disable :show_exceptions
class UserError < Exception; end
error UserError do
  status 400
  env['sinatra.error'].message
end

######################################################
def validate_symbol(symbol)
  if symbol !~ /^\w+$/
    raise UserError, "invalid stock symbol: #{symbol.inspect}"
  end
end

######################################################
class PricePoint
  attr_reader :time, :price

  # e.g. "123,45.67" and "123,45" are both valid strings
  PARSE_PATTERN = /^\s* (\d+) \s*,\s* (\d+(\.\d+)?) \s*$/x

  def self.parse(text)
    if text !~ PARSE_PATTERN
      raise UserError, "not a valid price point: #{text}"
    end

    time = Time.at($1.to_i)
    price = $2.to_f
    PricePoint.new(time, price)
  end

  def initialize(time, price)
    @time, @price = time, price
  end

  def to_s
    "time=#{time} price=#{price}"
  end
end

######################################################
class StockAnalyzer
  def add(price_point)
    if !point_added?
      @prev_point = price_point
      @buy_point = price_point
      @sell_point = price_point
      @min_point = price_point
      return
    end

    if price_point.time <= @prev_point.time
      raise UserError, "price point not in chronological order: #{price_point}"
    end

    # track previous point to verify chronological order
    @prev_point = price_point

    # track lowest point seen so far
    if price_point.price < @min_point.price
      @min_point = price_point
    end

    # update buy/sell points if selling at this point
    # (and buying at min point) yields better gains
    if price_point.price - @min_point.price >
        @sell_point.price - @buy_point.price
      @buy_point = @min_point
      @sell_point = price_point
    end
  end

  def buy_point
    validate_has_results
    @buy_point
  end

  def sell_point
    validate_has_results
    @sell_point
  end

  private

  def point_added?
    !@prev_point.nil?
  end

  def validate_has_results
    if !point_added?
      raise UserError, 'need at least one point to compute buy/sell points'
    end
  end
end

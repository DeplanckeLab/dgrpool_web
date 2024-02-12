module Algo

  class << self

    def r(x, y)
      # # # # # # # # # # # # 
      # - # # # # # #  Array # # # # # # 
      # - # # # # # # 
      # - # # # # # # # # # # # # 
      raise "Argument is not a Array class!"  unless y.class == Array
      raise "Self array is nil!"              if x.size == 0
      raise "Argument array size is invalid!" unless x.size == y.size
      
      # x # # # # # , y # # # # #  (arithmetic mean)
      mean_x = x.inject(0) { |s, a| s += a } / x.size.to_f
      mean_y = y.inject(0) { |s, a| s += a } / y.size.to_f
      # x #  y # # # # # # #  (covariance)
      cov = x.zip(y).inject(0) { |s, a| s += (a[0] - mean_x) * (a[1] - mean_y) }
      # x # # # # # # , y # # # # # #  (variance)
      var_x = x.inject(0) { |s, a| s += (a - mean_x) ** 2 }
      var_y = y.inject(0) { |s, a| s += (a - mean_y) ** 2 }
      # # # # #  (correlation coefficient)
      r = cov / Math.sqrt(var_x)
      r /= Math.sqrt(var_y)
    end
    
    def rcc_kendall(x, y)
      # # # # # # # # # # # # 
      # - # # # # # #  Array # # # # # # 
      # - # # # # # # 
      # - # # # # # # # # # 
      # - # # # # # # # # # # # # # 
      raise "Argument is not a Array class!"  unless y.class == Array
      raise "Self array is nil!"              if  x.size == 0
      raise "Argument array size is invalid!" unless x.size == y.size
      (x + y).each do |v|
        raise "Items except numerical values exist!" unless v.to_s =~ /[\d\.]+/
      end
      
      # # # # # # 
      # ( # # # # # # ( # # ) # # (mid-rank)# # # # # # # # ) 
      rank_x = x.map { |v| x.count { |a| a > v } + 1 }
      rank_y = y.map { |v| y.count { |a| a > v } + 1 }
      # P( x_s #  x_t, y_s #  y_t # # # # # # # # # # # # # ) 
      # Q( x_s #  x_t, y_s #  y_t # # # # # # # # # # # # # ) 
      # ( x_s = x_t or y_s = y_t # # # ) 
      n, p, q = x.size, 0, 0
      0.upto(n - 2).each do |i|
        (i + 1).upto(n - 1).each do |j|
          w = (rank_x[i] - rank_x[j]) * (rank_y[i] - rank_y[j])
          case
          when w > 0; p += 1
          when w < 0; q += 1
          end
        end
      end
      # # # # 
      tai_x = rank_x.group_by { |a| a }.map do |k, v|
        [k, v.size]
      end.to_h.select { |k, v| v > 1 }
      tai_y = rank_y.group_by { |a| a }.map do |k, v|
        [k, v.size]
      end.to_h.select { |k, v| v > 1 }
      # Tx, Ty #  sum # # 
      t_x = tai_x.map { |a| (a[1] * a[1] * a[1] - a[1]) / 2.0 }.sum
      t_y = tai_y.map { |a| (a[1] * a[1] * a[1] - a[1]) / 2.0 }.sum
      # # # # # 
      nn = (n * n - n) / 2.0
      return (p - q) / (Math.sqrt(nn - t_x) * Math.sqrt(nn - t_y))
    end
    
    
  end
end

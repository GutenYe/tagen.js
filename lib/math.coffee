_.reopenClass Math,
  mod: (val, mod) ->
    if val < 0
      val += mod while val < 0
      val
    else 
      val % mod

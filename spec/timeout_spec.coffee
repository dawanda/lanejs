describe "Lib.Timeout", ->

  it "fulfills the promise after the timeout", ( done ) ->
    start = ( new Date ).getTime()
    Lib.Timeout.start( 100 ).then ->
      elapsed = ( new Date ).getTime() - start
      expect( elapsed ).toBeGreaterThan 99
      expect( elapsed ).toBeLessThan 103
      done()

  it "supports a simpler 'setTimout-like but with better args order' syntax", ( done ) ->
    start = ( new Date ).getTime()
    Lib.Timeout.start 100, ->
      elapsed = ( new Date ).getTime() - start
      expect( elapsed ).toBeGreaterThan 99
      expect( elapsed ).toBeLessThan 103
      done()

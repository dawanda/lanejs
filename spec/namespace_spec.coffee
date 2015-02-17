describe "window.namespace", ->

  it "has been declared", ->
    expect( window.namespace ).not.toBe(undefined)

  it "contructs the correct variable", ->
    ns = "a.b.c"
    window.namespace ns, -> "test"
    expect( window.a.b.c ).toBe("test")

  it "defaults to {} in case of no function parameter", ->
    ns = "a.b.c"
    window.namespace ns
    expect( window.a.b.c ).not.toBe({})

  it "throws a TypeError if some thing other than a function is passed", ->
    expect( ->
      ns = "a.b.c"
      window.namespace ns, {}
    ).toThrowError("second argument of 'namespace' should be a function")

  it "constructs the correct variable for repeating scopes", ->
    ns = "a.a.a"
    window.namespace ns, -> "test"
    expect( window.a.a.a ).toBe("test")

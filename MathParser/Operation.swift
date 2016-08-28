//
//  Operation.swift
//  MathParser
//
//  Created by Lenny Khazan on 8/27/16.
//  Copyright © 2016 Lenny Khazan. All rights reserved.
//

import Darwin // math functions

public protocol Operation {
    var terms: [Operation] { get }
    func evaluate() -> Value
}

public struct Value: Operation {
    public let terms: [Operation] = []
    public let value: Double
    
    public func evaluate() -> Value {
        return self
    }
}

public struct AdditionOperation: Operation {
    public let terms: [Operation]
    
    public func evaluate() -> Value {
        assert(terms.count == 2, "Attempted to evaluate AdditionOperation with \(terms.count) " +
            "terms instead of 2.")
        
        let value = terms[0].evaluate().value + terms[1].evaluate().value
        return Value(value: value)
    }
}

public struct SubtractionOperation: Operation {
    public let terms: [Operation]
    
    public func evaluate() -> Value {
        assert(terms.count == 2, "Attempted to evaluate SubtractionOperation with \(terms.count) " +
            "terms instead of 2.")
        
        let value = terms[0].evaluate().value - terms[1].evaluate().value
        return Value(value: value)
    }
}

public struct MultiplicationOperation: Operation {
    public let terms: [Operation]
    
    public func evaluate() -> Value {
        assert(terms.count == 2, "Attempted to evaluate MultiplicationOperation with " +
            "\(terms.count) terms instead of 2.")
        
        let value = terms[0].evaluate().value * terms[1].evaluate().value
        return Value(value: value)
    }
}

public struct DivisionOperation: Operation {
    public let terms: [Operation]
    
    public func evaluate() -> Value {
        assert(terms.count == 2, "Attempted to evaluate DivisionOperation with \(terms.count) " +
            "terms instead of 2.")
        
        let dividend = terms[0].evaluate().value
        let divisor = terms[1].evaluate().value
        
        assert(divisor != 0, "Divisor of DivisionOperation evaluated to 0.");
        
        let quotient = dividend / divisor
        return Value(value: quotient)
    }
}

public struct ExponentOperation: Operation {
    public let terms: [Operation]
    
    public func evaluate() -> Value {
        assert(terms.count == 2, "Attempted to evaluate ExponentOperation with \(terms.count) " +
            "terms instead of 2.")
        
        let base = terms[0].evaluate().value
        let exponent = terms[1].evaluate().value
        
        return Value(value: pow(base, exponent))
    }
}

public struct ScientificNotationOperation: Operation {
    public let terms: [Operation]
    
    public func evaluate() -> Value {
        assert(terms.count == 2, "Attempted to evaluate ScientificNotationOperation with " +
            "\(terms.count) terms instead of 2.")
        
        return Value(value: terms[0].evaluate().value * pow(10.0, terms[1].evaluate().value))
    }
}

public struct FunctionOperation: Operation {
    public let terms: [Operation]
    public let function: ([Operation]) -> Value
    
    public func evaluate() -> Value {
        return function(terms)
    }
    
    public static func functionWithName(name: String,
                                 terms: [Operation],
                                 parserConfiguration: ParserConfiguration)
        -> FunctionOperation? {
            switch name {
            case "sin":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate sin function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    var term = terms[0].evaluate().value
                    if parserConfiguration.angleUnits == .Degrees {
                        term = term * M_PI / 180.0
                    }
                    
                    return Value(value: sin(term))
                }
            case "cos":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate cos function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    var term = terms[0].evaluate().value
                    if parserConfiguration.angleUnits == .Degrees {
                        term = term * M_PI / 180.0
                    }
                    
                    return Value(value: cos(term))
                }
            case "tan":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate tan function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    var term = terms[0].evaluate().value
                    if parserConfiguration.angleUnits == .Degrees {
                        term = term * M_PI / 180.0
                    }
                    
                    return Value(value: tan(term))
                }
            case "arcsin":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate arcsin function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    var value = asin(terms[0].evaluate().value)
                    if parserConfiguration.angleUnits == .Degrees {
                        value = value * 180.0 / M_PI
                    }
                    
                    return Value(value: value)
                }
            case "arccos":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate arccos function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    var value = acos(terms[0].evaluate().value)
                    if parserConfiguration.angleUnits == .Degrees {
                        value = value * 180.0 / M_PI
                    }
                    
                    return Value(value: value)
                }
            case "arctan":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate arctan function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    var value = atan(terms[0].evaluate().value)
                    if parserConfiguration.angleUnits == .Degrees {
                        value = value * 180.0 / M_PI
                    }
                    
                    return Value(value: value)
                }
            case "sqrt":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate sqrt function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    return Value(value: sqrt(terms[0].evaluate().value))
                }
            case "rad":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 2, "Attempted to evaluate rad function with \(terms.count) " +
                        "terms instead of 2.")
                    
                    return Value(value: pow(terms[0].evaluate().value, 1 / terms[1].evaluate().value))
                }
            case "log":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate log function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    return Value(value: log(terms[0].evaluate().value))
                }
            case "ln":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate ln function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    return Value(value: log2(terms[0].evaluate().value))
                }
            case "avg":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    let sum = terms.reduce(0.0, combine: { (accumulator, term) -> Double in
                        return accumulator + term.evaluate().value
                    })
                    
                    return Value(value: sum / Double(terms.count))
                }
            case "min":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    let vals = terms.map({ (term) -> Double in
                        return term.evaluate().value
                    })
                    
                    return Value(value: vals.minElement()!)
                }
            case "max":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    let vals = terms.map({ (term) -> Double in
                        return term.evaluate().value
                    })
                    
                    return Value(value: vals.maxElement()!)
                }
            case "med":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    var vals = terms.map({ (term) -> Double in
                        return term.evaluate().value
                    })
                    
                    vals.sortInPlace()
                    
                    let med: Double
                    if vals.count % 2 == 0 {
                        med = (vals[vals.count / 2] + vals[vals.count / 2 - 1]) / 2
                    } else {
                        med = vals[vals.count / 2]
                    }
                    
                    return Value(value: med)
                }
            case "factorial":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate factorial function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    var factorial = 1.0
                    for i in 1 ... Int(terms[0].evaluate().value) {
                        factorial *= Double(i)
                    }
                    
                    return Value(value: factorial)
                }
            case "ceil":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate ceil function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    return Value(value: ceil(terms[0].evaluate().value))
                }
            case "floor":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate floor function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    return Value(value: floor(terms[0].evaluate().value))
                }
            case "int":
                return FunctionOperation(terms: terms) { (terms) -> Value in
                    assert(terms.count == 1, "Attempted to evaluate int function with \(terms.count) " +
                        "terms instead of 1.")
                    
                    return Value(value: Double(Int(terms[0].evaluate().value)))
                }
            default:
                return nil
            }
    }
}
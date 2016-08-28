//
//  Parser.swift
//  MathParser
//
//  Created by Lenny Khazan on 8/27/16.
//  Copyright © 2016 Lenny Khazan. All rights reserved.
//

public enum OperationType {
    case Addition
    case Subtraction
    case Multiplication
    case Division
    case Exponent
    case ScientificNotation
    case Function(String)
}

public enum Token {
    case Number(Double)
    case Operation(OperationType)
    case OpenParenthesis
    case CloseParenthesis
    case Comma
    
    func precedence() -> Int {
        switch self {
        case .Operation(let opType):
            switch opType {
            case .Addition, .Subtraction:
                return 1
            case .Multiplication, .Division:
                return 2
            case .Exponent, .ScientificNotation:
                return 3
            case .Function(_):
                return 4
            }
        default:
            return 0
        }
    }
}

public enum ParserError: ErrorType {
    case SyntaxError
}

public struct ParserConfiguration {
    public enum AngleUnits {
        case Degrees
        case Radians
    }
    
    public var angleUnits: AngleUnits = .Degrees
}

public class Parser {
    public var parserConfiguration = ParserConfiguration()
    
    public func parse(string: String) -> [Token] {
        var tokens: [Token] = []
        
        // Number and function tokens span multiple characters, so we keep track of the current
        // number/function we are processing here.
        var currentNumber = ""
        var currentFunction = ""
        
        for character in string.characters {
            // Update currentNumber if we're in a number
            switch character {
            case "0" ... "9", ".":
                currentNumber.append(character)
            default:
                if currentNumber != "" {
                    tokens.append(.Number(Double(currentNumber)!))
                }
                
                currentNumber = ""
            }
            
            // Update currentFunction if we're in a function
            switch character {
            case "a" ... "z":
                currentFunction.append(character)
            default:
                if currentFunction != "" {
                    tokens.append(.Operation(.Function(currentFunction)))
                }
                
                currentFunction = ""
            }
            
            // We're not in a function or number, so continue parsing.
            switch character {
            case "+":
                tokens.append(.Operation(.Addition))
            case "-":
                if tokens.count == 0 {
                    currentNumber = "-"
                    break
                }
                
                switch tokens.last! {
                case .OpenParenthesis, .Operation(_), .Comma:
                    currentNumber = "-"
                    break
                default:
                    tokens.append(.Operation(.Subtraction))
                }
            case "*":
                tokens.append(.Operation(.Multiplication))
            case "/":
                tokens.append(.Operation(.Division))
            case "^":
                tokens.append(.Operation(.Exponent))
            case "E":
                tokens.append(.Operation(.ScientificNotation))
            case "(":
                tokens.append(.OpenParenthesis)
            case ")":
                tokens.append(.CloseParenthesis)
            case ",":
                tokens.append(.Comma)
            default:
                break
            }
        }
        
        // Tie up loose ends
        if currentNumber != "" {
            tokens.append(.Number(Double(currentNumber)!))
        } else if currentFunction != "" {
            tokens.append(.Operation(.Function(currentFunction)))
        }
        
        return tokens
    }
    
    public func buildTree(tokens: [Token]) throws -> Operation? {
        var mutableTokens = tokens
        
        // We start by adding in the implicit multiply operations
        var idx = 0
        while idx < mutableTokens.count - 1 {
            switch (mutableTokens[idx], mutableTokens[idx+1]) {
            case (.Number(_), .OpenParenthesis),
                 (.Number(_), .Operation(.Function(_))),
                 (.CloseParenthesis, .Number(_)),
                 (.CloseParenthesis, .Operation(.Function(_))),
                 (.CloseParenthesis, .OpenParenthesis):
                mutableTokens.insert(.Operation(.Multiplication), atIndex: idx+1)
            default:
                break
            }
            
            idx += 1
        }
        
        // Then we convert the series of tokens to a postfix expression
        var postfixExpression: [Token] = []
        var operatorStack: [Token] = []
        
        for token in mutableTokens {
            switch token {
            case .Number(_):
                postfixExpression.append(token)
            case .OpenParenthesis:
                operatorStack.append(token)
            case .CloseParenthesis:
                // When we hit a close parenthesis, pop the operator stack until we find the open
                // parenthesis. Note that we treat commas differently - we count how many we hit
                // while popping the op stack, but don't add them to the postfix expression. If
                // there is a function token immediately before the open paren, we add the number
                // of parameters (commas + 1) and the function to the postfix expression.
                var commas = 0
                while let op = operatorStack.popLast() {
                    if case .OpenParenthesis = op { break }
                    if case .Comma = op {
                        commas += 1
                    } else {
                        postfixExpression.append(op)
                    }
                }
                
                if let op = operatorStack.popLast() {
                    if case .Operation(.Function(_)) = op {
                        postfixExpression.append(.Number(Double(commas + 1)))
                        postfixExpression.append(op)
                    } else if commas > 0 {
                        throw ParserError.SyntaxError
                    } else {
                        operatorStack.append(op)
                    }
                }
            case .Operation(_):
                while let op = operatorStack.popLast() {
                    if op.precedence() >= token.precedence() {
                        postfixExpression.append(op)
                    } else {
                        operatorStack.append(op)
                        break
                    }
                }
                
                operatorStack.append(token)
            case .Comma:
                while let op = operatorStack.popLast() {
                    if case .OpenParenthesis = op {
                        operatorStack.append(op)
                        break
                    } else if case .Comma = op {
                        operatorStack.append(op)
                        break
                    } else {
                        postfixExpression.append(op)
                    }
                }
                operatorStack.append(token)
            }
        }
        
        while let op = operatorStack.popLast() {
            postfixExpression.append(op)
        }
        
        // Construct the expression tree
        var expressionStack: [Operation] = []
        for token in postfixExpression {
            switch token {
            case .Number(let number):
                expressionStack.append(Value(value: number))
            case .Operation(.Addition):
                let rightTerm = expressionStack.popLast()!
                let leftTerm = expressionStack.popLast()!
                let terms = [leftTerm, rightTerm]
                expressionStack.append(AdditionOperation(terms: terms))
            case .Operation(.Subtraction):
                let rightTerm = expressionStack.popLast()!
                let leftTerm = expressionStack.popLast()!
                let terms = [leftTerm, rightTerm]
                expressionStack.append(SubtractionOperation(terms: terms))
            case .Operation(.Multiplication):
                let rightTerm = expressionStack.popLast()!
                let leftTerm = expressionStack.popLast()!
                let terms = [leftTerm, rightTerm]
                expressionStack.append(MultiplicationOperation(terms: terms))
            case .Operation(.Division):
                let rightTerm = expressionStack.popLast()!
                let leftTerm = expressionStack.popLast()!
                let terms = [leftTerm, rightTerm]
                expressionStack.append(DivisionOperation(terms: terms))
            case .Operation(.Exponent):
                let rightTerm = expressionStack.popLast()!
                let leftTerm = expressionStack.popLast()!
                let terms = [leftTerm, rightTerm]
                expressionStack.append(ExponentOperation(terms: terms))
            case .Operation(.ScientificNotation):
                let rightTerm = expressionStack.popLast()!
                let leftTerm = expressionStack.popLast()!
                let terms = [leftTerm, rightTerm]
                expressionStack.append(ScientificNotationOperation(terms: terms))
            case .Operation(.Function(let name)):
                
                let numTerms = Int(expressionStack.popLast()!.evaluate().value)
                var terms = (0..<numTerms).map({ (_) -> Operation in
                    return expressionStack.popLast()!
                })
                
                terms = terms.reverse()
                
                let op = FunctionOperation.functionWithName(name, terms: terms, parserConfiguration: parserConfiguration)
                expressionStack.append(op!)
            case .OpenParenthesis, .CloseParenthesis, .Comma:
                break
            }
        }
        
        if expressionStack.count > 0 {
            return expressionStack[0]
        } else {
            return nil
        }
    }
}
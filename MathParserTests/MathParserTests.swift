//
//  MathParserTests.swift
//  MathParserTests
//
//  Created by Lenny Khazan on 8/27/16.
//  Copyright © 2016 Lenny Khazan. All rights reserved.
//

import XCTest
@testable import MathParser

class MathParserTests: XCTestCase {
    
    let parser = Parser()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func assertExpression(string: String, expected: Double) {
        do {
            let tokens = parser.parse(string)
            let result = try parser.buildTree(tokens)?.evaluate().value
            XCTAssertEqualWithAccuracy(result!, expected, accuracy: 0.00001, "\(string) = \(expected), not \(result)")
        } catch {
            XCTAssert(false, "Crashed while evaluating \(string)")
        }
    }
    
    func testNumber() {
        assertExpression("5", expected: 5)
    }
    
    func testDecimal() {
        assertExpression("35.425", expected: 35.425)
    }
    
    func testNegative() {
        assertExpression("-23.4", expected: -23.4)
    }
    
    func testParenthesesMultiplication() {
        assertExpression("43(24)", expected: 43 * 24)
        assertExpression("(43)24", expected: 43 * 24)
        assertExpression("(43)(24)", expected: 43 * 24)
    }
    
    func testAddition() {
        assertExpression("13.45+24", expected: 13.45 + 24)
    }
    
    func testSubtraction() {
        assertExpression("32-42.4", expected: 32 - 42.4)
        assertExpression("432-2", expected: 432 - 2)
    }
    
    func testMultiplication() {
        assertExpression("4*23.4", expected: 4 * 23.4)
    }
    
    func testDivision() {
        assertExpression("24/2", expected: 12)
        assertExpression("234/4242", expected: 234/4242)
    }
    
    func testExponent() {
        assertExpression("23^2", expected: pow(23, 2))
        assertExpression("5^1.5", expected: pow(5, 1.5))
        assertExpression("4.234^0.22", expected: pow(4.234, 0.22))
    }
    
    func testScientificNotation() {
        assertExpression("0.42E2", expected: 42)
        assertExpression("10E-1", expected: 1)
    }
    
    func testFunctions() {
        assertExpression("sqrt(5)", expected: sqrt(5))
        assertExpression("sqrt(sqrt(50))", expected: sqrt(sqrt(50)))
        assertExpression("rad(27, rad(9,2))", expected: 3)
        assertExpression("sqrt(4)rad(27,3)", expected: 6)
        assertExpression("rad(sqrt(81),sqrt(4))", expected: 3)
        assertExpression("5+2sqrt(9 + rad(49,2))", expected: 13)
        assertExpression("log(425)", expected: log(425))
        assertExpression("log(1)", expected: 0)
        assertExpression("ln(636)", expected: log2(636))
        assertExpression("avg(100,100,100,100)", expected: 100)
        assertExpression("avg(52+52)", expected: 104)
        assertExpression("min(5,25,25,0,-52)", expected: -52)
        assertExpression("max(5+254, sqrt(525), rad(53674,4))", expected: 259)
        assertExpression("med(1240,-431,20)", expected: 20)
        assertExpression("med(-42,0,40,35245)", expected: 20)
        assertExpression("factorial(4)", expected: 4*3*2)
        assertExpression("ceil(30.3)", expected: 31)
        assertExpression("floor(45.9)", expected: 45)
        assertExpression("int(3445.242)", expected: 3445)
        assertExpression("min((45),(424+42)/25,rad(52,2))", expected: sqrt(52))
    }
    
    func testTrigFunctions() {
        parser.parserConfiguration.angleUnits = .Radians
        assertExpression("tan(5)", expected: tan(5))
        assertExpression("tan(254)", expected: tan(254))
        assertExpression("sin(54)", expected: sin(54))
        assertExpression("cos(2)", expected: cos(2))
        assertExpression("sin(42+24)", expected: sin(42+24))
        assertExpression("cos(224^2 - 35 * 4)", expected: cos(pow(224, 2) - 35 * 4))
        assertExpression("arcsin(0)", expected: 0)
        assertExpression("arccos(0)", expected: acos(0))
        assertExpression("arctan(325)", expected: atan(325))
        
        parser.parserConfiguration.angleUnits = .Degrees
        assertExpression("sin(180)", expected: sin(M_PI))
        assertExpression("arcsin(3.1415926535/4)", expected: asin(M_PI_4) * 180.0 / M_PI)
    }
    
    func testRads() {
        assertExpression("sqrt(9.3)", expected: sqrt(9.3))
        assertExpression("rad(27,3)", expected: 3)
    }
    
    func testComplexExpressions() {
        assertExpression("32-42(12.23)^3-3*1.5", expected: 32 - 42 * pow(12.23, 3) - 3 * 1.5)
        assertExpression("(23/4 * 3 - 2)^0.5 + 324 - 34 * 32*24", expected: pow(23.0/4.0*3.0-2, 0.5) + 324 - 34 * 32 * 24)
    }
}

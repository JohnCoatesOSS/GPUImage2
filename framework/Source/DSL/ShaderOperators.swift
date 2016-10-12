import Foundation

class vec4: Shader.Variable {
    var uniformInitialValue: Double?
    
    var xy: vec2 {
        let name = referenceValue
        return vec2(name: name + ".xy", type: type,
                    function: function,
                    qualifier: qualifier,
                    shader: shader)
    }
    
    convenience init(_ value: Double) {
        self.init(type: .vec4)
        uniformInitialValue = value
    }
    
    override var declaration: String? {
        if !qualifier.isDeclared {
            return nil
        }
        guard let name = name else {
            fatalError("Can't declare a nameless variable!")
        }
        if let uniformInitialValue = uniformInitialValue {
            #if GLES
                if let precision = precision {
                    return "\(qualifier) \(precision.rawValue) \(type) \(name) = vec4(\(uniformInitialValue);"
                }
            #endif
            return "\(qualifier) \(type) \(name) = vec4(\(uniformInitialValue);"
        } else {
            return super.declaration
        }
        
    }
    
    override var value: String {
        if let uniformInitialValue = uniformInitialValue {
            return "vec4(\(uniformInitialValue))"
        } else {
            fatalError("vec4 value not implemented")
        }
    }
}

class gfloat: Shader.Variable {
    var realValue: Double?
    
    /// Initialize a vector with the specified elements.
    convenience init(_ value: Double) {
        self.init(value: value)
    }
    
    /// Initialize a vector with the specified elements.
    convenience init(value: Double) {
        self.init(type: .int)
        self.realValue = value
    }
    
    override var value: String {
        guard let realValue = realValue else {
            fatalError("Missing real value")
        }
        return String(realValue)
    }
}

typealias ShaderClosure = (Shader)->Void
func buildShader(_ closure: ShaderClosure) -> Shader {
    let shader = Shader()
    closure(shader)
    return shader
}

@discardableResult func == (lhs: VariableProtocol, rhs: VariableProtocol) -> Shader.Statement {
    let statement = Shader.Statement(type: .assignment, lhs: lhs, rhs: rhs)
    
    if let function = lhs.function {
        function.addStatement(statement)
        return statement
    }
    
    guard let shader = lhs.shader else {
        fatalError("Variable \(lhs) is missing shader, can't add statement: \(statement)")
    }
    
    shader.addStatement(statement)
    return statement
}

@discardableResult func += (lhs: vec4, rhs: Shader.Statement) -> Shader.Statement {
    let statement = Shader.Statement(type: .addAndAssign, lhs: lhs, rhs: rhs)
    
    if let function = lhs.function {
        function.addStatement(statement)
        return statement
    }
    
    guard let shader = lhs.shader else {
        fatalError("Variable \(lhs) is missing shader, can't add statement: \(statement)")
    }
    
    shader.addStatement(statement)
    return statement
}

@discardableResult func == (lhs: gint, rhs: Int) -> Shader.Statement {
    let rhsVariable = gint(value: rhs)
    return lhs == rhsVariable
}

precedencegroup ShaderAssignmentPrecedence {
    lowerThan: AdditionPrecedence
    higherThan: AssignmentPrecedence
}

infix operator ==: ShaderAssignmentPrecedence

func * (lhs: vec2, rhs: gfloat) -> Shader.Statement {
    return Shader.Statement(type: .multiplication, lhs: lhs, rhs: rhs)
}

func - (lhs: vec2, rhs: Shader.Statement) -> Shader.Statement {
    return Shader.Statement(type: .subtraction, lhs: lhs, rhs: rhs)
}

func + (lhs: vec2, rhs: Shader.Statement) -> Shader.Statement {
    return Shader.Statement(type: .addition, lhs: lhs, rhs: rhs)
}

func * (lhs: vec2, rhs: Double) -> Shader.Statement {
    let float = gfloat(rhs)
    return Shader.Statement(type: .multiplication, lhs: lhs, rhs: float)
}

func * (lhs: Shader.Statement, rhs: Double) -> Shader.Statement {
    let float = gfloat(rhs)
    return Shader.Statement(type: .multiplication, lhs: lhs, rhs: float)
}

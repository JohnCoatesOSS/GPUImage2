import Foundation

class Shader: CustomStringConvertible {
    
    // MARK: - Init
    
    var precision: Precision
    var shader: String
    init(precision: Precision = .low) {
        self.precision = precision
        self.shader = ""
    }
    
    // MARK: - Function Creation
    
    lazy var functions = [Function]()
    
    var currentFunction: Function?
    
    typealias FunctionClosure = (Function)->Void
    func makeFunction(named name: String, closure: FunctionClosure) {
        let function = Function(name: name, shader: self)
        functions.append(function)
        
        currentFunction = function
        closure(function)
        currentFunction = nil
    }
    
    // MARK: - Statement Addition
    
    func addStatement(_ statement: Statement) {
        guard let currentFunction = currentFunction else {
            print("Tried to add statement \"\(statement)\" with no current function!")
            return
        }
        
        currentFunction.addStatement(statement)
    }
    
    class GlobalVariable: Variable {
        
    }
    
    class VariablesContainer {
        weak var shader: Shader!
        let qualifier: GlobalVariable.Qualifier
        
        lazy var existing = [Variable]()
        init(shader: Shader, qualifier: GlobalVariable.Qualifier) {
            self.shader = shader
            self.qualifier = qualifier
        }
    }
    
    class GlobalVariableContainer {
        weak var shader: Shader!
        let qualifier: GlobalVariable.Qualifier
        init(shader: Shader, qualifier: GlobalVariable.Qualifier) {
            self.shader = shader
            self.qualifier = qualifier
        }
    }
    
    // MARK: - Function
    
    class Function {
        lazy var variables: FunctionVariablesContainer = FunctionVariablesContainer(function: self)
        
        let name: String
        weak var shader: Shader!
        init(name: String, shader: Shader) {
            self.name = name
            self.shader = shader
        }
        
        var statements = [Statement]()
        func addStatement(_ statement: Statement) {
            statements.append(statement)
        }
    }
    
    class FunctionVariablesContainer {
        lazy var existing = [Variable]()
        weak var function: Function!
        init(function: Function) {
            self.function = function
        }
    }
    
    // MARK: - Globals
    
    lazy var globals = [Variable]()
    lazy var attributes: GlobalVariableContainer = GlobalVariableContainer(shader: self, qualifier: .attribute)
    lazy var varyings: GlobalVariableContainer = GlobalVariableContainer(shader: self, qualifier: .varying)
    lazy var builtIns: GlobalVariableContainer = GlobalVariableContainer(shader: self, qualifier: .builtIn)
    lazy var uniforms: GlobalVariableContainer = GlobalVariableContainer(shader: self, qualifier: .uniform)
    
    func add(global: Variable) {
        guard !globals.contains(where: {$0.name == global.name}) else {
            return
        }
        globals.append(global)
    }
    
    // MARK: - Enums
    enum Precision: String {
        case low = "lowp"
        case medium = "mediump"
        case high = "highp"
    }
    
    // MARK: - String Conversion
    
    public var description: String {
        get {
            var contents = ""
            
            for global in globals {
                guard let declaration = global.declaration else {
                    continue
                }
                
                contents += "\(declaration)\n"
            }
            
            contents += "\n"
            for function in functions {
                contents += "\(function)\n"
            }
            
            return contents
        }
    }
    
    // MARK: - Basic Types
    
    //    enum ValueType {
    //        case Uniform
    //        case BuiltIn
    //        case Varying
    //        case Attribute
    //        case FunctionVariable
    //        case NamedConstant
    //        case UnnamedConstant
    //    }
    
    enum ValueType: String, CustomStringConvertible {
        case int
        case float
        case vec2
        case vec3
        case vec4
        case sampler2D
        
        var description: String {
            return rawValue
        }
    }
    
    class Variable: Value, VariableProtocol {
        
        // reference: https://www.opengl.org/wiki/Type_Qualifier_(GLSL)
        enum Qualifier: String, CustomStringConvertible {
            case none
            case uniform
            case attribute
            case varying
            case builtIn
            var isDeclared: Bool {
                if self == .builtIn {
                    return false
                } else {
                    return true
                }
            }
            var description: String {
                return rawValue
            }
        }
        
        var name: String?
        var precision: Precision?
        let qualifier: Qualifier
        let type: ValueType
        var needsDeclarationForAssignment = true
        var needsDeclarationBeforeAssignment = false
        
        // global
        weak var shader: Shader?
        init(name: String, type: ValueType, qualifier: Qualifier, shader: Shader) {
            if qualifier == .none {
                fatalError("Global variable requires a qualifier!")
            }
            self.name = name
            self.type = type
            self.qualifier = qualifier
            self.shader = shader
            needsDeclarationForAssignment = false
        }
        
        // function
        weak var function: Function?
        init(name: String, type: ValueType, function: Function) {
            self.name = name
            self.type = type
            self.function = function
            self.qualifier = .none
        }
        
        convenience init(name: String, type: ValueType,
                         function: Function?,
                         qualifier: Qualifier?, shader: Shader?) {
            if let function = function {
                self.init(name: name, type: type, function: function)
                return
            }
            
            guard let shader = shader, let qualifier = qualifier else {
                fatalError("Missing function or shader & qualifier")
            }
            
            self.init(name: name, type: type, qualifier: qualifier, shader: shader)
        }
        
        // constant
        init(type: ValueType) {
            self.type = type
            self.qualifier = .none
        }
        
        var declaration: String? {
            if !qualifier.isDeclared {
                return nil
            }
            guard let name = name else {
                fatalError("Can't declare a nameless variable!")
            }
            #if GLES
                if let precision = precision {
                    return "\(qualifier) \(precision.rawValue) \(type) \(name);"
                }
            #endif
            return "\(qualifier) \(type) \(name);"
        }
        
        var referenceValue: String {
            if let name = name {
                return name
            } else {
                return value
            }
        }
        
        var declarationReference: String {
            guard let name = name else {
                fatalError("Can't declare a nameless variable!")
            }
            #if GLES
                if let precision = precision {
                    return "\(precision.rawValue) \(type) \(name)"
                }
            #endif
            return "\(type) \(name)"
        }
        
        var assignable: Bool {
            return true
        }
        
        var value: String {
            fatalError("Type class \(self) must override this variable!")
        }
    }
    
    class Constant: Value {
        
    }
    
    class Value {
        
    }
    
}

extension Shader.Function: CustomStringConvertible {
    
    public var description: String {
        get {
            var contents = "void \(name)() { \n"
            
            for statement in statements {
                contents += "\t\(statement);\n"
            }
            
            contents += "}\n"
            
            return contents
        }
    }
}

// MARK: - Function Variable Container
extension Shader.FunctionVariablesContainer {
    
    subscript (name: String) -> gfloat {
        get {
            if let existing = self.existing.filter({$0.name == name}).first {
                return existing as! gfloat
            }
            let variable = gfloat(name: name, type: .float, function: function)
            existing.append(variable)
            return variable
        }
    }
    
    subscript (name: String) -> vec2 {
        get {
            if let existing = self.existing.filter({$0.name == name}).first {
                return existing as! vec2
            }
            
            let variable = vec2(name: name, type: .vec2, function: function)
            existing.append(variable)
            return variable
        }
    }
    
    subscript (name: String) -> vec4 {
        get {
            if let existing = self.existing.filter({$0.name == name}).first {
                return existing as! vec4
            }
            
            let variable = vec4(name: name, type: .vec4, function: function)
            existing.append(variable)
            return variable
        }
    }
    
    subscript (name: String) -> gint {
        get {
            if let existing = self.existing.filter({$0.name == name}).first {
                return existing as! gint
            }
            
            let variable = gint(name: name, type: .int, function: function)
            existing.append(variable)
            return variable
        }
    }
}

// MARK: - Global Variable Container

extension Shader.GlobalVariableContainer {
    
    subscript (name: String) -> gfloat {
        get {
            let global = gfloat(name: name, type: .float, qualifier: qualifier, shader: shader)
            shader.add(global: global)
            return global
        }
    }
    
    subscript (name: String) -> vec4 {
        get {
            let global = vec4(name: name, type: .vec4, qualifier: qualifier, shader: shader)
            shader.add(global: global)
            return global
        }
    }
    
    subscript (name: String) -> sampler2D {
        get {
            let global = sampler2D(name: name,
                                   type: .sampler2D,
                                   qualifier: qualifier,
                                   shader: shader)
            shader.add(global: global)
            return global
        }
    }
    
    // MARK: - Arrays
    
    subscript (name: String) -> ShaderArray<vec2> {
        get {
            let global = ShaderArray<vec2>(name: name, type: .vec2,
                                           qualifier: qualifier, shader: shader)
            shader.add(global: global)
            return global
        }
    }
    
    subscript (name: String) -> ShaderArray<gfloat> {
        get {
            let global = ShaderArray<gfloat>(name: name, type: .float,
                                             qualifier: qualifier, shader: shader)
            shader.add(global: global)
            return global
        }
    }
}

// MARK: - Statement

class gint: Shader.Variable {
    var realValue: Int?
    
    /// Initialize a vector with the specified elements.
    convenience init(_ value: Int) {
        self.init(value: value)
    }
    
    /// Initialize a vector with the specified elements.
    convenience init(value: Int) {
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

// MARK: - sampler2D

class sampler2D: Shader.Variable {
    
}

func texture2D(_ sampler: sampler2D, _ coord: VariableProtocol) -> Shader.Statement {
    return texture2D(sampler: sampler, coordinates: coord)
}

func texture2D(sampler: sampler2D,
               coordinates: VariableProtocol) -> Shader.Statement {
    return Shader.Statement(type: .texture2D,
                            lhs: sampler,
                            rhs: coordinates)
}

// MARK: - Vec2

class vec2: Shader.Variable {
    
    var x: Float?
    var y: Float?
    var xReference: gfloat?
    var yReference: gfloat?
    
    convenience init() {
        self.init(x: 0, y: 0)
    }
    
    /// Initialize a vector with the specified elements.
    convenience init(_ x: Float, _ y: Float) {
        self.init(x: x, y: y)
    }
    
    /// Initialize a vector with the specified elements.
    convenience init(x: Float, y: Float) {
        self.init(type: .vec2)
        self.x = x
        self.y = y
    }
    
    convenience init(_ x: gfloat, _ y: gfloat) {
        self.init(type: .vec2)
        xReference = x
        yReference = y
    }
    
    override var value: String {
        if x != nil, y != nil {
            return concreteValue
        } else {
            return pointerValue
        }
    }
    
    var concreteValue: String {
        guard let x = x,
            let y = y else {
                fatalError("Missing value for concrete value")
        }
        return "vec2(\(x), \(y))"
    }
    
    var pointerValue: String {
        guard let xReference = xReference,
            let yReference = yReference else {
                fatalError("Missing reference for reference value")
        }
        
        return "vec2(\(xReference.referenceValue), \(yReference.referenceValue))"
    }
}

protocol VariableProtocol: class {
    var name: String? { get }
    var referenceValue: String { get }
    var declarationReference: String { get }
    
    var assignable: Bool { get }
    var needsDeclarationForAssignment: Bool { get set }
    var needsDeclarationBeforeAssignment: Bool { get set }
    
    var shader: Shader? { get }
    var function: Shader.Function? { get }
}

import Foundation

class ShaderArray<Element: Shader.Variable>: Shader.Variable,
MutableCollection, RandomAccessCollection, ExpressibleByArrayLiteral {
    private var elements: [Element] = []
    
    typealias Indices = Array<Element>.Indices
    
    required init(arrayLiteral elements: Element...) {
        super.init(type: .vec2)
    }
    
    override init(name: String,
                  type: Shader.ValueType,
                  qualifier: Qualifier,
                  shader: Shader) {
        super.init(name: name, type: type, qualifier: qualifier, shader: shader)
        self.shader = shader
    }
    
    init(elements data: [Element] = []) {
        self.elements = data
        super.init(type: .vec2)
    }
    
    private var _count: Int = 0
    var count: Int {
        get {
            return _count
        }
        set {
            _count = newValue
        }
    }
    
    var startIndex: Int {
        return elements.startIndex
    }
    
    var endIndex: Int {
        return elements.endIndex
    }
    
    func index(after i: Int) -> Int {
        return elements.index(after: i)
    }
    
    func index(before i: Int) -> Int {
        return elements.index(before: i)
    }
    
    subscript(position: Int) -> Element {
        get {
            guard let name = name else {
                fatalError("Array must have name to be subscripted")
            }
            let variableName = "\(name)[\(position)]"
            
            switch type {
            case .float:
                return gfloat(name: variableName, type:type,
                              function: function,
                              qualifier: qualifier,
                              shader: shader) as! Element
            case .vec2:
                return vec2(name: variableName, type: type,
                            function: function,
                            qualifier: qualifier,
                            shader: shader) as! Element
            default:
                fatalError("Missing init")
            }
            return elements[position]
        }
        set {
            elements[position] = newValue
        }
    }
    
    subscript(bounds: Range<Int>) -> ShaderArray<Element> {
        get {
            return ShaderArray(elements: Array(elements[bounds]))
        }
        set {
            elements[bounds] = ArraySlice(newValue.elements)
        }
    }
    
    // MARK: - Overrides
    
    override var declaration: String? {
        if !qualifier.isDeclared {
            return nil
        }
        guard let name = name else {
            fatalError("Can't declare a nameless variable!")
        }
        #if GLES
            if let precision = precision {
                return "\(qualifier) \(precision.rawValue) \(type) \(name)[\(count)];"
            }
        #endif
        return "\(qualifier) \(type) \(name)[\(count)];"
    }
    
    override var declarationReference: String {
        guard let name = name else {
            fatalError("Can't declare a nameless variable!")
        }
        #if GLES
            if let precision = precision {
                return "\(precision.rawValue) \(type) \(name)[\(count)]"
            }
        #endif
        
        return "\(type) \(name)[\(count)]"
    }
}

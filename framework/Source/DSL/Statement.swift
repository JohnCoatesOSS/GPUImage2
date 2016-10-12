import Foundation

extension Shader {
    class Statement: VariableProtocol, CustomStringConvertible {
        enum StatementType {
            case assignment
            case multiplication
            case addition
            case subtraction
            case texture2D
            case addAndAssign
        }
        
        var statementType: StatementType
        let lhs: VariableProtocol?
        let rhs: VariableProtocol?
        var lhsFirstAssignment = false
        init(type: StatementType, lhs: VariableProtocol, rhs: VariableProtocol) {
            self.statementType = type
            self.lhs = lhs
            self.rhs = rhs
            if type == .assignment {
                checkLHSForFirstAssignment(lhs: lhs)
            }
        }
        
        func checkLHSForFirstAssignment(lhs: VariableProtocol) {
            guard lhs.assignable else {
                fatalError("This variable \(lhs.name) is not assignable!")
            }
            if lhs.needsDeclarationForAssignment {
                lhsFirstAssignment = true
                lhs.needsDeclarationForAssignment = false
            }
        }
        
        var description: String {
            switch statementType {
            case .assignment:
                return assignmentDescription(withAssignmentOperator: "=")
            case .addAndAssign:
                return assignmentDescription(withAssignmentOperator: "+=")
            case .multiplication:
                return operationDescription(withOperator: "*")
            case .addition:
                return operationDescription(withOperator: "+")
            case .subtraction:
                return operationDescription(withOperator: "-")
            case .texture2D:
                return wrapperDescription(withWrapper: "texture2D")
            }
        }
        
        func operationDescription(withOperator operation: String) -> String {
            guard let lhs = lhs, let rhs = rhs else {
                fatalError("Operator \(operation) is missing a variable")
            }
            
            let lhsReference = lhs.referenceValue
            let rhsReference = rhs.referenceValue
            return "\(lhsReference) \(operation) \(rhsReference)"
        }
        
        func wrapperDescription(withWrapper wrapperName: String) -> String {
            guard let lhs = lhs, let rhs = rhs else {
                fatalError("Wrapper \(wrapperName) is missing a variable")
            }
            
            let lhsReference = lhs.referenceValue
            let rhsReference = rhs.referenceValue
            return "\(wrapperName)(\(lhsReference), \(rhsReference))"
        }
        
        func assignmentDescription(withAssignmentOperator operation: String) -> String {
            guard let lhs = lhs, let rhs = rhs else {
                fatalError("Assignment statement is missing a variable")
            }
            
            let lhsReference: String
            if lhsFirstAssignment && !lhs.needsDeclarationBeforeAssignment {
                lhsReference = lhs.declarationReference
            } else {
                lhsReference = lhs.referenceValue
            }
            
            let rhsReference = rhs.referenceValue
            
            return "\(lhsReference) \(operation) \(rhsReference)"
        }
        
        // MARK: - Variable Protocol
        
        var name: String? = nil
        
        var referenceValue: String {
            return description
        }
        var assignable = false
        var declarationReference: String {
            fatalError("Invalid: Statement can't be declared")
        }
        
        var needsDeclarationForAssignment = false
        var needsDeclarationBeforeAssignment = false
        
        var shader: Shader? {
            if let shader = lhs?.shader {
                return shader
            } else {
                return rhs?.shader
            }
        }
        
        var function: Function? {
            if let function = lhs?.function {
                return function
            } else {
                return rhs?.function
            }
        }
    }
}

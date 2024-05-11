classdef Evaluator < handle
    properties
        ast
    end

    methods
        function evaluator = Evaluator(ast)
            evaluator.ast = ast;
        end

        function results = evaluate(eval)
            results = [];

            for node = eval.ast
                result = eval.evalNode(node);
                if result.kind == "error"
                    fprintf("error: %s\n", result.left);
                    results = [];
                    break;
                end

                results = [results, result];
            end
        end

        function result = evalNode(eval, node)
            switch node.kind
                case "unary"
                    result = eval.evalUnary(node.operator, node.left);
                case "binary"
                    result = eval.evalBinary(node.operator, node.left, node.right);
                case "group"
                    result = eval.evalNode(node.left);
                case "number"
                    result = node;
                case "error"
                    result = node;
                otherwise
                    result.kind = "error";
                    result.left = "invalid AST node";
            end
        end

        function result = evalUnary(eval, op, value)
            value = eval.evalNode(value);
            
            if op == "numNeg" && value.kind == "number"
                result.kind = "number";
                result.left = -value.left;
            else
                result.kind = "error";
                result.left = "cannot negate a non-number";
            end
        end

        function result = evalBinary(eval, op, left, right)
            left =  eval.evalNode(left);
            right = eval.evalNode(right);

            switch op
                case "add"
                    if all([left.kind, right.kind] == "number")
                        result.kind = "number";
                        result.left = left.left + right.left;
                    else
                        result.kind = "error";
                        result.left = "cannot add two non-numbers";
                    end
                case "sub"
                    if all([left.kind, right.kind] == "number")
                        result.kind = "number";
                        result.left = left.left - right.left;
                    else
                        result.kind = "error";
                        result.left = "cannot subtract two non-numbers";
                    end
                case "mul"
                    if all([left.kind, right.kind] == "number")
                        result.kind = "number";
                        result.left = left.left * right.left;
                    else
                        result.kind = "error";
                        result.left = "cannot multiply two non-numbers";
                    end
                case "div"
                    if all([left.kind, right.kind] == "number")
                        if right.left == 0
                            result.kind = "error";
                            result.left = "cannot divide by 0";
                        else
                            result.kind = "number";
                            result.left = left.left / right.left;
                        end
                    else
                        result.kind = "error";
                        result.left = "cannot divide with two non-numbers";
                    end
                case "rem"
                    if all([left.kind, right.kind] == "number")
                        result.kind = "number";
                        result.left = rem(left.left, right.left);
                    else
                        result.kind = "error";
                        result.left = "cannot multiply two non-numbers";
                    end
                case "pow"
                    if all([left.kind, right.kind] == "number")
                        result.kind = "number";
                        result.left = left.left ^ right.left;
                    end
                otherwise
                    result.kind = "error";
                    result.left = "invalid binary operation";
            end
        end
    end
end

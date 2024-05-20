classdef Evaluator < handle
    properties
        ast
        vars
    end

    methods
        function evaluator = Evaluator(ast)
            evaluator.ast = ast;
            evaluator.vars = containers.Map("KeyType", "char", "ValueType", "any");
        end

        function node = createNode(~, kind, op, left, right)
            node.kind = kind;
            node.operator = op;
            node.left = left;
            node.right = right;
        end

        function includeBuiltIns(eval)
            builtIns = "pi = 3.14159265358979323846;" + ...
                "e = 2.718281828459045;";

            lexer = Lexer(builtIns);
            lexer.tokenize;
    
            parser = Parser(lexer.tokens);
            parser.parse;
        
            evaluator = Evaluator(parser.ast);
            evaluator.evaluate(false);

            eval.vars = evaluator.vars;
        end

        function results = evaluate(eval, include)
            if include
                eval.includeBuiltIns;
            end

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
                case "ident"
                    try
                        result = eval.vars(node.left);
                    catch
                        result = eval.createNode("array", [], [], []);
                    end
                case "unary"
                    result = eval.evalUnary(node.operator, node.left);
                case "binary"
                    result = eval.evalBinary(node.operator, node.left, node.right);
                case "group"
                    result = eval.evalNode(node.left);
                case "array"
                    result = eval.createNode("array", [], [], []);
                    for elem = node.left
                        result.left = [result.left, eval.evalNode(elem)];
                    end
                case "number"
                    result = node;
                case "error"
                    result = node;
                otherwise
                    result = eval.createNode("error", [], "invalid AST node", []);
            end
        end

        function result = evalUnary(eval, op, value)
            value = eval.evalNode(value);
            
            if op == "numNeg" && value.kind == "number"
                result = eval.createNode("number", [], -value.left, []);
            else
                result = eval.createNode("error", [], "cannot negate a non-number");
            end
        end

        function result = add(eval, left, right)
            if all([left.kind, right.kind] == "number")
                result = eval.createNode("number", [], left.left + right.left, []);
            elseif all([left.kind, right.kind] == "array")
                result = eval.createNode("array", [], [], []);
                
                leftarr = arrayfun(@(node) eval.evalNode(node), left.left);
                rightarr = arrayfun(@(node) eval.evalNode(node), right.left);
                
                if length(leftarr) ~= length(rightarr)
                    result.kind = "error";
                    result.left = "invalid array operation";
                else
                    added = [];

                    interleaved = [leftarr;rightarr];
                    for index = 1:length(interleaved)
                        pair = interleaved(:, index);
                        added = [added, eval.add(pair(1), pair(2))];
                    end
                    
                    result.left = added;
                end
            elseif left.kind == "array" && right.kind == "number"
                result = eval.createNode("array", [], [], []);
                result.left = arrayfun(@(elem) eval.add(elem, right), left.left);
            elseif left.kind == "number" && right.kind == "array"
                result = eval.createNode("array", [], [], []);
                result.left = arrayfun(@(elem) eval.add(elem, left), right.left);
            else
                result = eval.createNode( ...
                    "error", ...
                    [], ...
                    sprintf("failed to add %s and %s", eval.toStr(left), eval.toStr(right)), ...
                    []...
                );
            end
        end

        function result = sub(eval, left, right)
            if all([left.kind, right.kind] == "number")
                result = eval.createNode("number", [], left.left - right.left, []);
            elseif all([left.kind, right.kind] == "array")
                result = eval.createNode("array", [], [], []); leftarr = arrayfun(@(node) eval.evalNode(node), left.left);
                rightarr = arrayfun(@(node) eval.evalNode(node), right.left);
                
                if length(leftarr) ~= length(rightarr)
                    result.kind = "error";
                    result.left = "invalid array operation";
                else
                    subbed = [];

                    interleaved = [leftarr;rightarr];
                    for index = 1:length(interleaved)
                        pair = interleaved(:, index);
                        subbed = [subbed, eval.sub(pair(1), pair(2))];
                    end
                    
                    result.left = subbed;
                end
            elseif left.kind == "array" && right.kind == "number"
                result = eval.createNode("array", [], [], []);
                result.left = arrayfun(@(elem) eval.sub(elem, right), left.left);
            else
                result = eval.createNode( ...
                    "error", ...
                    [], ...
                    sprintf("failed to subtract %s from %s", eval.toStr(right), eval.toStr(left)), ...
                    []...
                );
            end
        end

        function result = mul(eval, left, right)
            if all([left.kind, right.kind] == "number")
                result = eval.createNode("number", [], left.left * right.left, []);
            elseif all([left.kind, right.kind] == "array")
                result = eval.createNode("array", [], [], []);

                leftarr = arrayfun(@(node) eval.evalNode(node), left.left);
                rightarr = arrayfun(@(node) eval.evalNode(node), right.left);
                
                if length(leftarr) ~= length(rightarr)
                    result.kind = "error";
                    result.left = "invalid array operation";
                else
                    subbed = [];

                    interleaved = [leftarr;rightarr];
                    for index = 1:length(interleaved)
                        pair = interleaved(:, index);
                        subbed = [subbed, eval.mul(pair(1), pair(2))];
                    end
                    
                    result.left = subbed;
                end
            elseif left.kind == "array" && right.kind == "number"
                result = eval.createNode("array", [], [], []);
                result.left = arrayfun(@(elem) eval.mul(elem, right), left.left);
            elseif left.kind == "number" && right.kind == "array"
                result = eval.createNode("array", [], [], []);
                result.left = arrayfun(@(elem) eval.mul(elem, left), right.left);
            else
                result = eval.createNode( ...
                    "error", ...
                    [], ...
                    sprintf("failed to multiply %s by %s", eval.toStr(left), eval.toStr(right)), ...
                    []...
                );
            end
        end
        
        function result = div(eval, left, right)
            if right.left == 0
                result = eval.createNode("error", [], "cannot divide by 0", []);
            elseif all([left.kind, right.kind] == "number")
                result = eval.createNode("number", [], left.left / right.left, []);
            elseif all([left.kind, right.kind] == "array")
                result = eval.createNode("array", [], [], []);
                
                leftarr = arrayfun(@(node) eval.evalNode(node), left.left);
                rightarr = arrayfun(@(node) eval.evalNode(node), right.left);
                
                if length(leftarr) ~= length(rightarr)
                    result.kind = "error";
                    result.left = "invalid array operation";
                else
                    subbed = [];

                    interleaved = [leftarr;rightarr];
                    for index = 1:length(interleaved)
                        pair = interleaved(:, index);
                        subbed = [subbed, eval.div(pair(1), pair(2))];
                    end
                    
                    result.left = subbed;
                end
            elseif left.kind == "array" && right.kind == "number"
                result = eval.createNode("array", [], [], []);
                result.left = arrayfun(@(elem) eval.div(elem, right), left.left);
            else
                result = eval.createNode( ...
                    "error", ...
                    [], ...
                    sprintf("failed to divide %s by %s", eval.toStr(left), eval.toStr(right)), ...
                    []...
                );
            end
        end

        function result = remainder(eval, left, right)
            if all([left.kind, right.kind] == "number")
                result = eval.createNode("number", [], rem(left.left, right.left), []);
            elseif all([left.kind, right.kind] == "array")
                result = eval.createNode("array", [], [], []);

                leftarr = arrayfun(@(node) eval.evalNode(node), left.left);
                rightarr = arrayfun(@(node) eval.evalNode(node), right.left);
                
                if length(leftarr) ~= length(rightarr)
                    result.kind = "error";
                    result.left = "invalid array operation";
                else
                    subbed = [];

                    interleaved = [leftarr;rightarr];
                    for index = 1:length(interleaved)
                        pair = interleaved(:, index);
                        subbed = [subbed, eval.remainder(pair(1), pair(2))];
                    end
                    
                    result.left = subbed;
                end
            elseif left.kind == "array" && right.kind == "number"
                result = eval.createNode("array", [], [], []);
                result.left = arrayfun(@(elem) eval.remainder(elem, right), left.left);
            else
                result = eval.createNode( ...
                    "error", ...
                    [], ...
                    sprintf("failed to find remainder of %s with %s", eval.toStr(left), eval.toStr(right)), ...
                    []...
                );
            end
        end
        
        function result = pow(eval, left, right)
            if all([left.kind, right.kind] == "number")
                result = eval.createNode("number", [], left.left ^ right.left, []);
            elseif all([left.kind, right.kind] == "array")
                result = eval.createNode("array", [], [], []);

                leftarr = arrayfun(@(node) eval.evalNode(node), left.left);
                rightarr = arrayfun(@(node) eval.evalNode(node), right.left);
                
                if length(leftarr) ~= length(rightarr)
                    result.kind = "error";
                    result.left = "invalid array operation";
                else
                    subbed = [];

                    interleaved = [leftarr;rightarr];
                    for index = 1:length(interleaved)
                        pair = interleaved(:, index);
                        subbed = [subbed, eval.pow(pair(1), pair(2))];
                    end
                    
                    result.left = subbed;
                end
            elseif left.kind == "array" && right.kind == "number"
                result = eval.createNode("array", [], [], []);
                result.left = arrayfun(@(elem) eval.pow(elem, right), left.left);
            else
                result = eval.createNode( ...
                    "error", ...
                    [], ...
                    sprintf("failed to pow: %s ^ %s", eval.toStr(left), eval.toStr(right)), ...
                    []...
                );
            end
        end

        function [left, right] = evalLeftRight(eval, left, right)
            left = eval.evalNode(left);
            right = eval.evalNode(right);
        end

        function result = evalBinary(eval, op, left, right)
            switch op
                case "assign"
                    right = eval.evalNode(right);
                    eval.vars(left.left) = right;
                    result = right;
                case "add"
                    [left, right] = eval.evalLeftRight(left, right);
                    result = eval.add(left, right);
                case "sub"
                    [left, right] = eval.evalLeftRight(left, right);
                    result = eval.sub(left, right);
                case "mul"
                    [left, right] = eval.evalLeftRight(left, right);
                    result = eval.mul(left, right);
                case "div"
                    [left, right] = eval.evalLeftRight(left, right);
                    result = eval.div(left, right);
                case "rem"
                    [left, right] = eval.evalLeftRight(left, right);
                    result = eval.remainder(left, right);
                case "pow"
                    [left, right] = eval.evalLeftRight(left, right);
                    result = eval.pow(left, right);
                otherwise
                    result.kind = "error";
                    result.left = "invalid binary operation";
            end
        end

        function str = toStr(eval, node)
            switch node.kind
                case "number"
                    str = num2str(node.left);
                case "array"
                    str = "[";
                    for val = node.left
                        str = sprintf("%s %s", str, eval.toStr(val));
                    end
                    str = sprintf("%s ]", str);
            end
        end
    end
end

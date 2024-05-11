classdef Parser < handle
    properties
        tokens
        index
        current
        ast
    end

    methods
        function parser = Parser(tokens)
            parser.tokens = tokens;
            parser.index = 0;
            parser.current = struct("kind", "start", "value", []);
            parser.ast = [];
        end

        function parse(parser)
            parser.advance;
            
            while ~parser.isEnd
                node = parser.parseStmt;

                if node.kind ~= "error"
                    parser.appendNode(node);
                else
                    fprintf("Error: %s\n", node.left);
                    break;
                end
            end
        end

        function node = parseStmt(parser)
            node = parser.parseExpr;
            
            if node.kind == "error"
                return;
            elseif parser.current.kind ~= ';'
                
                fprintf("tokens: ");
                for token = parser.tokens
                    fprintf("%s ", token.kind);
                end
                fprintf("\n");

                node = parser.createError("expected ';'");
            else
                parser.advance;
            end
        end

        function node = parseExpr(parser)
            node = parser.parseTerm;
        end

        function node = parseTerm(parser)
            node = parser.parseFactor;

            while true
                if node.kind == "error"
                    return;
                elseif parser.current.kind == '+'
                    parser.advance;
                    right = parser.parseFactor;
                    if right.kind == "error"
                        node = right;
                    else
                        node = parser.createBinaryNode("add", node, right);
                    end
                elseif parser.current.kind == "-"
                    parser.advance;
                    right = parser.parseFactor;
                    if right.kind == "error"
                        node = right;
                    else
                        node = parser.createBinaryNode("sub", node, right);
                    end
                else
                    break;
                end
            end
        end

        function node = parseFactor(parser)
            node = parser.parsePower;

            while true
                if node.kind == "error"
                    return;
                elseif parser.current.kind == '/'
                    parser.advance;
                    right = parser.parsePower;
                    if right.kind == "error"
                        node = right;
                    else
                        node = parser.createBinaryNode("div", node, right);
                    end
                elseif parser.current.kind == '*'
                    parser.advance;
                    right = parser.parsePower;
                    if right.kind == "error"
                        node = right;
                    else
                        node = parser.createBinaryNode("mul", node, right);
                    end
                elseif parser.current.kind == '%'
                    parser.advance;
                    right = parser.parsePower;
                    if right.kind == "error"
                        node = right;
                    else
                        node = parser.createBinaryNode("rem", node, right);
                    end
                else
                    break;
                end
            end
        end

        function node = parsePower(parser)
            node = parser.parseUnary;

            while true
                if node.kind == "error"
                    return;
                elseif parser.current.kind == '^'
                    parser.advance;
                    right = parser.parseUnary;
                    if right.kind == "error"
                        node = right;
                    else
                        node = parser.createBinaryNode("pow", node, right);
                    end
                else
                    break;
                end
            end
        end

        function node = parseUnary(parser)
            if parser.current.kind == '-'
                parser.advance;
                value = parser.parseUnary;
                if value.kind == "error"
                    node = value;
                else
                    node = parser.createNegateNode("numNeg", value);
                end
            else
                node = parser.parsePrimary;
            end
        end

        function node = parsePrimary(parser)
            switch parser.current.kind
                case "number"
                    node = parser.createLiteralNode("number", parser.current.value);
                    parser.advance;
                case '('
                    parser.advance;
                    expr = parser.parseExpr;
                    if expr.kind == "error"
                        node = expr;
                    else
                        node = parser.createGroupNode(expr);
                        if parser.current.kind == ')'
                            parser.advance;
                        else
                            node = parser.createError("expected ')'");
                        end
                    end
                otherwise
                    node = parser.createError("invalid token");
            end
        end

        function currentToken = advance(parser)
            if ~parser.isEnd()
                parser.index = parser.index + 1;
                parser.current = parser.tokens(parser.index);
            end

            currentToken = parser.current;
        end

        function result = isEnd(parser)
            result = parser.current.kind == "EOF";
        end

        function appendNode(parser, node)
            parser.ast = [parser.ast, node];
        end

        function err = createError(~, msg)
            err.kind = "error";
            err.operator = [];
            err.left = msg;
            err.right = [];
        end

        function node = createNegateNode(~, operator, value)
            node.kind = "unary";
            node.operator = operator;
            node.left = value;
            node.right = [];
        end

        function node = createBinaryNode(~, operator, left, right)
            node.kind = "binary";
            node.operator = operator;
            node.left = left;
            node.right = right;
        end

        function node = createGroupNode(~, value)
            node.kind = "group";
            node.operator = [];
            node.left = value;
            node.right = [];
        end

        function node = createLiteralNode(~, kind, value)
            node.kind = kind;
            node.operator = [];
            node.left = value;
            node.right = [];
        end
    end
end

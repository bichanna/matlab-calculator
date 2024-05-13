classdef Lexer < handle
    properties
        source
        index
        current
        tokens
    end

    methods
        function lexer = Lexer(source)
            lexer.source = source{1};
            lexer.index = 0;
            lexer.current = ' ';
            lexer.tokens = [];
        end

        function tokenize(lexer)
            currentChar = lexer.advance;

            while ~lexer.isEnd
                % fprintf("Current: %s\n", lexer.current);
                switch currentChar
                    case ' '
                    case '\t'
                    case '\n'
                        1;
                    case '('
                        token = lexer.createNoValueToken("(");
                        lexer.appendToken(token);
                    case ')'
                        token = lexer.createNoValueToken(")");
                        lexer.appendToken(token);
                    case '+'
                        token = lexer.createNoValueToken("+");
                        lexer.appendToken(token);
                    case '-'
                        token = lexer.createNoValueToken("-");
                        lexer.appendToken(token);
                    case '*'
                        token = lexer.createNoValueToken("*");
                        lexer.appendToken(token);
                    case '/'
                        token = lexer.createNoValueToken("/");
                        lexer.appendToken(token);
                    case '%'
                        token = lexer.createNoValueToken("%");
                        lexer.appendToken(token);
                    case '^'
                        token = lexer.createNoValueToken("^");
                        lexer.appendToken(token);
                    case ';'
                        token = lexer.createNoValueToken(";");
                        lexer.appendToken(token);
                    case '['
                        token = lexer.createNoValueToken("[");
                        lexer.appendToken(token);
                    case ']'
                        token = lexer.createNoValueToken("]");
                        lexer.appendToken(token);
                    otherwise
                        if lexer.isNumber(currentChar)
                            token = lexer.tokenizeNumber();
                            lexer.appendToken(token);
                        else
                            lexer.index = -1;
                            fprintf("Invalid token: '%s'\n", currentChar);
                            break;
                        end
                end

                currentChar = lexer.advance;
                % fprintf("After advance: %s\n", lexer.current);
            end
            
            endToken = lexer.createNoValueToken("EOF");
            lexer.appendToken(endToken);
        end

        function newToken = tokenizeNumber(lexer)
            number = "";

            while lexer.isNumber(lexer.current)
                number = append(number, lexer.current);
                lexer.advance();
            end

            nextChar = lexer.nextChar;
            if all(lexer.current == '.') && all(lexer.isNumber(nextChar))
                number = append(number, lexer.current);
                lexer.advance();

                while lexer.isNumber(lexer.current)
                    number = append(number, lexer.current);
                    lexer.advance();
                end
            end
            
            % fprintf("Before: %s\n", lexer.current);
            lexer.revert();
            % fprintf("After: %s\n", lexer.current);

            num = str2double(number);
            newToken = lexer.createToken("number", num);
        end

        function result = nextChar(lexer)
            if lexer.isNextEnd()
                result = '\0';
            else
                result = lexer.source(lexer.index+1);
            end
        end

        function result = isNumber(~, char)
            result = isstrprop(char, "digit");
        end

        function newToken = createToken(~, kind, value)
            newToken.kind = kind;
            newToken.value = value;
        end

        function newToken = createNoValueToken(~, kind)
            newToken.kind = kind;
            newToken.value = [];
        end

        function appendToken(lexer, token)
            lexer.tokens = [lexer.tokens, token];
        end

        function revert(lexer)
            lexer.index = lexer.index - 1;
            lexer.current = lexer.source(lexer.index);
        end

        function currentChar = advance(lexer)
            lexer.index = lexer.index + 1;
            if ~lexer.isEnd
                lexer.current = lexer.source(lexer.index);
            else
                lexer.current = '\0';
            end

            currentChar = lexer.current;
        end

        function isNextEnd = isNextEnd(lexer)
            isNextEnd = lexer.index >= length(lexer.source) || lexer.index == -1;
        end

        function isEnd = isEnd(lexer)
            isEnd = lexer.index - 1 >= length(lexer.source) || lexer.index == -1;
        end
    end
end

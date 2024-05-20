function calculator(str)
    lexer = Lexer(str);
    lexer.tokenize;
    
    parser = Parser(lexer.tokens);
    parser.parse;

    evaluator = Evaluator(parser.ast);
    results = evaluator.evaluate(true);
    
    if ~isempty(results)
        fprintf("Results:\n");
        for result = results
            fprintf("%s\n", evaluator.toStr(result));
        end
    end
end
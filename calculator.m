function calculator(str)
    lexer = Lexer(str);
    lexer.tokenize;
    
    parser = Parser(lexer.tokens);
    parser.parse;

    evaluator = Evaluator(parser.ast);
    results = evaluator.evaluate;
    
    if ~isempty(results)
        fprintf("Results:\n");
        for result = results
            fprintf("%i\n", result.left);
        end
    end
end
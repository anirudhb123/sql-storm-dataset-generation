-- Performance benchmarking query for StackOverflow schema 
-- This query retrieves the most viewed posts along with user reputations and number of answers.
SELECT 
    P.Title,
    P.ViewCount,
    U.Reputation,
    P.AnswerCount,
    P.CreationDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Only questions
ORDER BY 
    P.ViewCount DESC
LIMIT 10;


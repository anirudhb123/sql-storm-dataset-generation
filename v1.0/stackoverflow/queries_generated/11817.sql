-- Performance benchmarking query for Stack Overflow schema

-- This query will measure the time taken to retrieve the most popular questions along with their associated information.
SELECT 
    P.Id AS PostId,
    P.Title,
    P.ViewCount,
    P.Score,
    P.CreationDate,
    P.AcceptedAnswerId,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    C.CommentCount,
    A.AnswerCount,
    T.TagName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY PostId) A ON P.Id = A.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
LEFT JOIN 
    PostLinks PL ON PL.PostId = P.Id
LEFT JOIN 
    Tags T ON PL.RelatedPostId = T.Id
WHERE 
    P.PostTypeId = 1 -- Only Questions
ORDER BY 
    P.Score DESC, P.ViewCount DESC
LIMIT 100; -- Returns the top 100 popular questions

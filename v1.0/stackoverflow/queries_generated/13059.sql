-- Performance benchmarking query to analyze posts with high activity and user engagement

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COUNT(C.Id) AS TotalComments,
    COUNT(V.Id) AS TotalVotes
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= DATEADD(year, -1, GETDATE()) -- posts created in the last year
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount, U.DisplayName, U.Reputation
ORDER BY 
    TotalVotes DESC, P.Score DESC -- order by most voted and highest score
LIMIT 100; -- limit to top 100 posts

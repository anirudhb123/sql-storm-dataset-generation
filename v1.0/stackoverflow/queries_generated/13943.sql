-- Performance benchmarking SQL query for Stack Overflow schema
-- This query retrieves the most popular posts along with the associated user information, along with their vote counts.

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount, -- Count of upvotes
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount -- Count of downvotes
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Only questions
ORDER BY 
    P.Score DESC, P.ViewCount DESC
LIMIT 100; -- Limit to top 100 popular posts

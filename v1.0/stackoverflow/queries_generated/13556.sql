-- Performance Benchmarking Query

-- This query retrieves the number of posts per user, the average score of their posts, and the number of votes received.
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AverageScore,
    SUM(V.VoteTypeId = 2) AS UpVotes,
    SUM(V.VoteTypeId = 3) AS DownVotes
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    PostCount DESC;

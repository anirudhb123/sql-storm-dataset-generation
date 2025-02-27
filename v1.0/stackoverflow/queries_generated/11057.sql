-- Performance benchmarking query to retrieve average view counts, scores, and reputation of users who posted the questions
SELECT 
    P.Id AS PostId,
    P.Title,
    P.ViewCount,
    P.Score,
    U.Reputation,
    AVG(P.ViewCount) OVER() AS AvgViewCount,
    AVG(P.Score) OVER() AS AvgScore,
    AVG(U.Reputation) OVER() AS AvgReputation
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Only questions
ORDER BY 
    P.CreationDate DESC
LIMIT 100;

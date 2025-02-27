-- Performance benchmarking query to analyze post activity and user interaction statistics
SELECT 
    U.DisplayName AS UserName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    COUNT(DISTINCT V.Id) AS TotalVotes,
    SUM(P.ViewCount) AS TotalViewCount,
    SUM(P.Score) AS TotalScore,
    AVG(P.CreationDate) AS AvgPostCreationDate,
    MAX(P.CreationDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    U.Reputation > 0 -- Consider only users with positive reputation
GROUP BY 
    U.DisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 10; -- Limit to top 10 users with most posts

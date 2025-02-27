-- Performance benchmarking query to analyze posts and their engagement metrics
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
    -- Calculate average views per day since creation
    CASE 
        WHEN P.CreationDate IS NOT NULL THEN P.ViewCount / 
        DATEDIFF(DAY, P.CreationDate, GETDATE()) 
        ELSE NULL 
    END AS AvgViewsPerDay,
    -- Calculate total votes for each post
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id) AS TotalVotes,
    -- Fetch PostHistory entries for each post
    (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = P.Id) AS EditCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Filter for posts created in the last year
ORDER BY 
    P.CreationDate DESC
LIMIT 100;  -- Limit results for performance consideration

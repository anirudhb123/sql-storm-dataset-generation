-- Performance Benchmarking Query
-- This query retrieves post statistics along with user information and post history types

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryCreationDate,
    PH.Comment
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.CreationDate >= '2023-01-01'  -- Example filter for posts created in 2023
ORDER BY 
    P.CreationDate DESC
LIMIT 100;  -- Limiting the output for better performance during benchmarking

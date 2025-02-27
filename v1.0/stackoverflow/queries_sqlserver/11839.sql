
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
    P.CreationDate >= '2023-01-01'  
GROUP BY 
    P.Id,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    U.DisplayName,
    U.Reputation,
    PH.PostHistoryTypeId,
    PH.CreationDate,
    PH.Comment
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

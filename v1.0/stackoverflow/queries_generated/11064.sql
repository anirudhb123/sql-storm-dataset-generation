-- Performance Benchmarking Query

-- Evaluate the performance of retrieving posts with detailed information including user and tag details
SELECT 
    P.Id AS PostId,
    P.Title,
    P.Body,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    T.TagName,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    PH.CreationDate AS PostHistoryDate,
    PHT.Name AS PostHistoryType
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    Tags T ON T.Id IN (SELECT UNNEST(string_to_array(P.Tags, '><')))
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    P.CreationDate > NOW() - INTERVAL '1 year'
ORDER BY 
    P.CreationDate DESC
LIMIT 100;

-- Performance Benchmarking Query
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.LastActivityDate,
    PH.UserDisplayName AS LastEditorDisplayName,
    PH.CreationDate AS LastEditDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.PostTypeId = 1 -- Filter for Questions
ORDER BY 
    P.CreationDate DESC
LIMIT 100; -- Limit to the latest 100 questions for benchmarking

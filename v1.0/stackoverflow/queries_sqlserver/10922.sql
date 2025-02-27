
SELECT 
    PH.PostId,
    PH.UserId,
    U.DisplayName AS UserDisplayName,
    PH.CreationDate AS EditDate,
    P.Title,
    P.Body,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.CreationDate AS PostCreationDate,
    P.LastActivityDate,
    P.Tags,
    P.AcceptedAnswerId,
    P.ClosedDate
FROM 
    PostHistory PH
JOIN 
    Posts P ON PH.PostId = P.Id
JOIN 
    Users U ON PH.UserId = U.Id
WHERE 
    PH.CreationDate >= '2023-01-01' AND PH.CreationDate < '2024-01-01'
GROUP BY 
    PH.PostId,
    PH.UserId,
    U.DisplayName,
    PH.CreationDate,
    P.Title,
    P.Body,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.CreationDate,
    P.LastActivityDate,
    P.Tags,
    P.AcceptedAnswerId,
    P.ClosedDate
ORDER BY 
    PH.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

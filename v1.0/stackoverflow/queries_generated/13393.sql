SELECT 
    P.Id AS PostID,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    C.Count AS CommentCount,
    B.Count AS BadgeCount,
    T.Count AS TagCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS Count FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS Count FROM Badges GROUP BY UserId) B ON U.Id = B.UserId
LEFT JOIN 
    (SELECT Id, Count FROM Tags) T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
WHERE 
    P.CreationDate >= '2023-01-01'
ORDER BY 
    P.CreationDate DESC
LIMIT 100;

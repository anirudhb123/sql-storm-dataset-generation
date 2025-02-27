
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.Reputation AS OwnerReputation,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        @row_number := @row_number + 1 AS RowNum
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    JOIN 
        (SELECT @row_number := 0) AS r
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    OwnerReputation,
    CommentCount,
    AnswerCount
FROM 
    RankedPosts
WHERE 
    RowNum <= 100  
ORDER BY 
    CreationDate DESC;


WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Reputation AS OwnerReputation,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2020-01-01'  
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerReputation,
        OwnerDisplayName,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats, (SELECT @rank := 0) AS r
    ORDER BY 
        Score DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerReputation,
    OwnerDisplayName
FROM 
    TopPosts
WHERE 
    Rank <= 10  
ORDER BY 
    Score DESC;


WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerName,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        pt.Name AS PostTypeName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
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
        OwnerName,
        OwnerReputation,
        PostTypeName,
        @row_number := IF(@post_type = PostTypeName, @row_number + 1, 1) AS Rank,
        @post_type := PostTypeName
    FROM 
        PostStats, (SELECT @row_number := 0, @post_type := '') AS vars
    ORDER BY 
        PostTypeName, Score DESC, ViewCount DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    OwnerName,
    OwnerReputation,
    PostTypeName
FROM 
    TopPosts
WHERE 
    Rank <= 10 
ORDER BY 
    PostTypeName, Score DESC;

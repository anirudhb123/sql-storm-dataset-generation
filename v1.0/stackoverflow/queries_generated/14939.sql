-- Performance benchmarking query for Stack Overflow schema
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
        p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
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
        ROW_NUMBER() OVER (PARTITION BY PostTypeName ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
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
    Rank <= 10 -- Get top 10 posts for each type
ORDER BY 
    PostTypeName, Score DESC;

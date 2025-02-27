-- Performance Benchmark Query: Retrieve Post Statistics with User and Tag Details

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Id AS UserId,
        u.DisplayName AS UserDisplayName,
        t.TagName,
        COUNT(c.Id) AS CommentCountByUser
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, '>'))::int)
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- posts from the last year
    GROUP BY 
        p.Id, u.Id, t.TagName
)
SELECT 
    PostId, 
    Title, 
    CreationDate, 
    ViewCount, 
    Score, 
    AnswerCount, 
    CommentCount, 
    FavoriteCount, 
    UserId, 
    UserDisplayName,
    ARRAY_AGG(TagName) AS Tags,
    SUM(CommentCountByUser) AS TotalCommentsByUser
FROM 
    PostStats
GROUP BY 
    PostId, Title, CreationDate, ViewCount, Score, AnswerCount, CommentCount, FavoriteCount, UserId, UserDisplayName
ORDER BY 
    ViewCount DESC;  -- Order by the most viewed posts

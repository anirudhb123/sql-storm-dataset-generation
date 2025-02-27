-- Performance Benchmarking Query for Stack Overflow Schema

WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCountTotal,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts created in the last year
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, 
        p.FavoriteCount, u.Reputation, u.DisplayName
)

SELECT 
    PostId,
    PostTypeId,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerReputation,
    OwnerDisplayName,
    CommentCountTotal,
    UpvoteCount,
    DownvoteCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = pm.PostId) AS EditCount
FROM 
    PostMetrics pm
ORDER BY 
    ViewCount DESC -- Order by ViewCount for performance insights
LIMIT 100; -- Limit to top 100 posts for analysis

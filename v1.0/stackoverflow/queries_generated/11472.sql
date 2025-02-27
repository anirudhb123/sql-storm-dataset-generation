-- Performance benchmarking query to analyze post activity in the Stack Overflow schema

WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        PostId,
        Title,
        COUNT(*) AS ActivityCount
    FROM 
        PostHistory
    WHERE 
        CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        PostId, Title
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.FavoriteCount,
    pm.LastActivityDate,
    pm.OwnerDisplayName,
    pa.ActivityCount
FROM 
    PostMetrics pm
LEFT JOIN 
    PostActivity pa ON pm.PostId = pa.PostId
ORDER BY 
    pm.ViewCount DESC, pm.Score DESC
LIMIT 100; -- Limit results to top 100 posts based on viewcount and score

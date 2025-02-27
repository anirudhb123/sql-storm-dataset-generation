-- Performance Benchmarking Query

WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        p.AnswerCount,
        p.AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Filtering for posts created in the last year
    GROUP BY 
        p.Id, u.DisplayName
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.AnswerCount,
    pm.AcceptedAnswerId,
    pm.OwnerDisplayName,
    pm.Tags,
    pm.TotalComments,
    pm.TotalUpVotes,
    pm.TotalDownVotes
FROM 
    PostMetrics pm
ORDER BY 
    pm.ViewCount DESC 
LIMIT 100; -- Limit to top 100 posts based on view count

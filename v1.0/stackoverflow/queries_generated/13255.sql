-- Performance Benchmarking Query
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
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
PostHistoryMetrics AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS RevisionCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.OwnerDisplayName,
    phm.RevisionCount,
    phm.LastEditedDate,
    pm.VoteCount
FROM 
    PostMetrics pm
LEFT JOIN 
    PostHistoryMetrics phm ON pm.PostId = phm.PostId
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC
LIMIT 100;

-- Performance benchmarking query to analyze post statistics

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerDisplayName,
    ps.PostTypeName,
    ps.VoteCount,
    COALESCE(phs.LastEditDate, 'Never') AS LastEditDate,
    COALESCE(phs.EditCount, 0) AS EditCount
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryStats phs ON ps.PostId = phs.PostId
ORDER BY 
    ps.CreationDate DESC
LIMIT 100;  -- Limit results for benchmarking

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name = 'Post Closed' AND 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        cp.CreationDate AS ClosedDate,
        COALESCE(cp.Comment, 'Not Closed') AS CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.ClosedDate,
    ps.CloseReason
FROM 
    PostStatistics ps
WHERE 
    ps.RankScore <= 5
ORDER BY 
    ps.Score DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;

SELECT 
    'Total Posts' AS Metric, 
    COUNT(*) AS Value 
FROM 
    Posts;

UNION ALL

SELECT 
    'Total Closed Posts' AS Metric, 
    COUNT(*) AS Value 
FROM 
    ClosedPosts;

UNION ALL

SELECT 
    'Total Users' AS Metric, 
    COUNT(DISTINCT u.Id) AS Value 
FROM 
    Users u
WHERE 
    u.Reputation > 0;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(o.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY PostId) AS o ON p.Id = o.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) AS c ON p.Id = c.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > NOW() - INTERVAL '30 days'
),
RecentHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        p.Title,
        p.ClosedDate,
        pt.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days' AND 
        pt.Name IN ('Post Closed', 'Post Reopened')
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        COUNT(rh.HistoryDate) FILTER (WHERE rh.HistoryDate IS NOT NULL) AS RecentHistoryCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentHistory rh ON rp.PostId = rh.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerName, rp.Score, rp.ViewCount, rp.AnswerCount, rp.CommentCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerName,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.RecentHistoryCount,
    CASE 
        WHEN ps.RecentHistoryCount = 0 THEN 'No recent changes'
        WHEN ps.RecentHistoryCount > 0 AND ps.Score < 0 THEN 'Negatively impacted'
        WHEN ps.RecentHistoryCount > 0 AND ps.Score >= 0 THEN 'Recently revised'
        ELSE 'Unclassified'
    END AS PostAnalysis
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;

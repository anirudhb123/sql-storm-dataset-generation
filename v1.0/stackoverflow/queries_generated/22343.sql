WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate, 
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10) AND ph.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
),
UsersWithBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(*) > 5
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.ScoreRank,
        rp.CommentCount,
        cp.FirstClosedDate,
        cp.LastClosedDate,
        cp.CloseCount,
        uwb.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        UsersWithBadges uwb ON rp.OwnerUserId = uwb.UserId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    COALESCE(ps.ScoreRank, 'No Rank') AS ScoreRank,
    COALESCE(ps.CommentCount, 0) AS CommentCount,
    COALESCE(ps.FirstClosedDate, 'Not Closed') AS FirstClosedDate,
    COALESCE(ps.LastClosedDate, 'Not Closed') AS LastClosedDate,
    COALESCE(ps.CloseCount, 0) AS CloseCount,
    COALESCE(ps.BadgeCount, 0) AS UserBadgeCount,
    CASE 
        WHEN ps.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PostStatistics ps
WHERE 
    ps.ViewCount > 100
    AND (ps.BadgeCount IS NULL OR ps.BadgeCount > 3)
ORDER BY 
    ps.ViewCount DESC, 
    ps.Score DESC
LIMIT 50

UNION ALL

SELECT 
    NULL AS PostId,
    'Summary Statistics' AS Title,
    NULL AS CreationDate,
    COUNT(*) AS TotalPosts,
    SUM(ViewCount) AS TotalViews,
    AVG(Score) AS AverageScore,
    COUNT(DISTINCT OwnerUserId) AS UniqueUsers
FROM 
    Posts
WHERE 
    CreationDate > NOW() - INTERVAL '1 year';

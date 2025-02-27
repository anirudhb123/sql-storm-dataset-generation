WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.Views,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '6 months'
    GROUP BY 
        b.UserId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Views,
        rp.CreationDate,
        pr.CloseReasons,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        ub.BadgeList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostCloseReasons pr ON rp.PostId = pr.PostId
    LEFT JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        rp.RankByScore <= 5
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.Views,
        ps.CreationDate,
        ps.CloseReasons,
        ps.UserBadgeCount,
        ps.BadgeList,
        CASE 
            WHEN ps.Score = 0 THEN 'No votes'
            WHEN ps.Score < 10 THEN 'Low Engagement'
            WHEN ps.Score BETWEEN 10 AND 50 THEN 'Moderate Engagement'
            ELSE 'High Engagement'
        END AS EngagementLevel
    FROM 
        PostStatistics ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.Views,
    tp.CreationDate,
    tp.CloseReasons,
    tp.UserBadgeCount,
    tp.BadgeList,
    tp.EngagementLevel,
    CASE 
        WHEN tp.CloseReasons IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(NULLIF(tp.BadgeList, ''), 'No Badges') AS FinalBadges
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate ASC;


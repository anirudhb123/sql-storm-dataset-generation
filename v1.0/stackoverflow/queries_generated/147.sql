WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        p.Id
),
PostHistoryAnalytics AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        MIN(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS FirstReopenedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId, 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.RankByScore,
    COALESCE(ph.LastClosedDate, 'Not Closed') AS LastClosedDate,
    COALESCE(ph.FirstReopenedDate, 'Not Reopened') AS FirstReopenedDate,
    ub.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAnalytics ph ON rp.PostId = ph.PostId
LEFT JOIN 
    UserBadges ub ON rp.UserId = ub.UserId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CommentCount DESC
LIMIT 10;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class IN (2, 3)) AS SilverBronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pb.EditCount,
    ub.GoldBadges,
    ub.SilverBronzeBadges,
    CASE 
        WHEN pp.Score > 10 THEN 'High Score'
        WHEN pp.Score BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    COALESCE(phs.LastEdited, 'Never') AS LastEdited
FROM 
    RankedPosts pp
JOIN 
    Users up ON pp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostHistoryStats phs ON pp.PostId = phs.PostId
WHERE 
    pp.rn = 1
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC
LIMIT 100;


WITH RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        CASE 
            WHEN p.Score >= 0 THEN 'Active'
            WHEN p.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ActivityStatus
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
BadgeSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.CommentCount,
    r.Upvotes,
    r.Downvotes,
    r.ActivityStatus,
    b.UserId,
    b.BadgeCount,
    b.GoldBadges,
    b.SilverBadges,
    b.BronzeBadges
FROM 
    RecentPostActivity r
LEFT JOIN 
    BadgeSummary b ON r.PostId = b.UserId
WHERE 
    (r.ActivityStatus IS NOT NULL OR b.BadgeCount IS NOT NULL)
ORDER BY 
    r.ViewCount DESC,
    b.BadgeCount DESC
LIMIT 100;

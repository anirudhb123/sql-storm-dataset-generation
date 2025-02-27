WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                              WHEN u.Reputation >= 1000 THEN 'Gold'
                                              WHEN u.Reputation BETWEEN 500 AND 999 THEN 'Silver'
                                              ELSE 'Bronze' 
                                          END ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        DATE_PART('day', CURRENT_TIMESTAMP - p.CreationDate) AS DaysOld
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    rp.Title AS RecentPostTitle,
    rp.DaysOld,
    pwc.CommentCount
FROM 
    RankedUsers u
LEFT JOIN 
    UserBadges ub ON u.UserId = ub.UserId
LEFT JOIN 
    RecentPosts rp ON u.UserId = rp.OwnerUserId
LEFT JOIN 
    PostsWithComments pwc ON rp.PostId = pwc.PostId
WHERE 
    (u.Reputation > 500 OR ub.GoldBadges IS NOT NULL)
    AND (rp.DaysOld < 15 OR pwc.CommentCount > 5)
    AND (ub.GoldBadges IS NULL OR ub.SilverBadges IS NULL OR ub.BronzeBadges IS NULL) -- At least one badge must be missing
ORDER BY 
    u.Reputation DESC,
    rp.DaysOld ASC
LIMIT 100;

-- Additional semantics: 
-- 1. Candidates are filtered by reputation and badge count.
-- 2. Posts are selected only if recent with a threshold of comment count.
-- 3. The query respects complex relationships among users, badges, and posts including outer joins, correlated filtering, and conditional aggregation.

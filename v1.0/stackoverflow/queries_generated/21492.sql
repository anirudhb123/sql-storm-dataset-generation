WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(LEFT(Tags, LENGTH(Tags) - 2), '><')))::varchar) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ntile(5) OVER (ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
CloseVotes AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.BadgeCount,
    p.PostId,
    p.Score,
    p.ViewCount,
    p.CreationDate,
    pt.Tag,
    COALESCE(cv.CloseVoteCount, 0) AS CloseVoteCount,
    CASE 
        WHEN u.BadgeCount > 5 THEN 'Achiever'
        WHEN u.Reputation >= 1000 THEN 'Veteran'
        ELSE 'Newbie' 
    END AS UserCategory,
    COALESCE(JSON_BUILD_OBJECT(
        'Gold', u.GoldBadges,
        'Silver', u.SilverBadges,
        'Bronze', u.BronzeBadges
    ), '{}'::json) AS BadgeDetails
FROM 
    UserBadgeStats u
JOIN 
    PostStats p ON u.UserId = p.OwnerUserId
JOIN 
    PopularTags pt ON pt.Tag = ANY(string_to_array(p.OwnerUserId::text, ','))
LEFT JOIN 
    CloseVotes cv ON cv.PostId = p.PostId
WHERE 
    (p.ScoreRank = 1 OR p.RecentPostRank = 1)
    AND u.BadgeCount IS NOT NULL
ORDER BY 
    p.ViewCount DESC, u.BadgeCount ASC
LIMIT 100;

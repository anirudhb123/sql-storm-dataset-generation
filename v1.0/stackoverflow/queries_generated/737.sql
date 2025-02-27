WITH UserBadges AS (
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
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserProfile AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AvgViewCount, 0) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    up.PostCount,
    up.TotalScore,
    up.AvgViewCount,
    RANK() OVER (ORDER BY up.TotalScore DESC) AS ScoreRank
FROM 
    UserProfile up
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.TotalScore DESC, 
    up.DisplayName ASC
LIMIT 10
OFFSET 0;

SELECT 
    p.Id AS PostId,
    p.Title,
    array_agg(t.TagName) AS Tags,
    CASE 
        WHEN ph.PostHistoryTypeId IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
LEFT JOIN 
    (SELECT 
         pt.PostId,
         string_to_array(pt.Tags, ',') AS TagName
     FROM 
         Posts pt
     WHERE 
         pt.PostTypeId = 1) t ON p.Id = t.PostId
GROUP BY 
    p.Id, p.Title, ph.PostHistoryTypeId
ORDER BY 
    PostStatus, p.Title;

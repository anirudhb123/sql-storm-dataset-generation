WITH UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopPosts AS (
    SELECT 
        Id,
        Title,
        OwnerUserId,
        Score,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY Score DESC) AS rn
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '30 days'
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId,
        ph.Comment,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN (SELECT Name FROM CloseReasonTypes WHERE Id = CAST(ph.Comment AS INTEGER))
            ELSE NULL
        END AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.Location,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    pp.Title AS TopPostTitle,
    pp.Score AS TopPostScore,
    pp.CreationDate AS TopPostDate,
    COUNT(DISTINCT ph.PostId) AS HistoryCount,
    STRING_AGG(DISTINCT ph.CloseReason, '; ') AS CloseReasons
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    TopPosts pp ON u.Id = pp.OwnerUserId AND pp.rn = 1
LEFT JOIN 
    PostHistoryDetails ph ON u.Id = ph.UserId
WHERE 
    u.Reputation >= (SELECT AVG(Reputation) FROM Users)
    AND u.Location IS NOT NULL
    AND (pp.Score IS NULL OR pp.Score <= (SELECT AVG(Score) FROM Posts))
GROUP BY 
    u.Id, pp.Title
ORDER BY 
    u.Reputation DESC, TopPostScore DESC NULLS LAST
LIMIT 50;

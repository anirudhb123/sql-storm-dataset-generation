WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgPostScore,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        ps.TotalPosts,
        ps.AvgPostScore,
        ps.TotalComments
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    DisplayName,
    Reputation,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    AvgPostScore,
    TotalComments
FROM 
    TopUsers
WHERE 
    TotalPosts IS NOT NULL
ORDER BY 
    Reputation DESC, TotalPosts DESC
LIMIT 50
UNION ALL
SELECT 
    'Total Users' AS DisplayName,
    COUNT(*) AS Reputation,
    SUM(GoldBadges) AS GoldBadges,
    SUM(SilverBadges) AS SilverBadges,
    SUM(BronzeBadges) AS BronzeBadges,
    SUM(TotalPosts) AS TotalPosts,
    AVG(AvgPostScore) AS AvgPostScore,
    SUM(TotalComments) AS TotalComments
FROM 
    TopUsers
HAVING 
    SUM(TotalPosts) > 0;

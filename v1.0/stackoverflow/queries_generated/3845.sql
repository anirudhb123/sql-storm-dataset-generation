WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS Upvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges, 
        TotalPosts, 
        TotalComments, 
        Upvotes,
        ROW_NUMBER() OVER (ORDER BY Upvotes DESC, TotalPosts DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    u.UserId, 
    u.DisplayName,
    u.GoldBadges, 
    u.SilverBadges, 
    u.BronzeBadges, 
    u.TotalPosts, 
    u.TotalComments, 
    u.Upvotes
FROM 
    TopUsers u
WHERE 
    u.Rank <= 10
UNION ALL
SELECT 
    0 AS UserId, 
    'Overall Totals' AS DisplayName,
    SUM(u.GoldBadges) AS GoldBadges, 
    SUM(u.SilverBadges) AS SilverBadges, 
    SUM(u.BronzeBadges) AS BronzeBadges, 
    SUM(u.TotalPosts) AS TotalPosts, 
    SUM(u.TotalComments) AS TotalComments, 
    SUM(u.Upvotes) AS Upvotes
FROM 
    TopUsers u
HAVING 
    COUNT(u.UserId) > 0
ORDER BY 
    UserId DESC;

WITH RankedUserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only questions
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        COUNT(PostId) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        RankedUserPosts
    WHERE 
        Rank <= 5 -- Top 5 posts by score for each user
    GROUP BY 
        UserId, DisplayName
),
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE 
            WHEN b.Class = 1 THEN 1 
            ELSE 0 
        END) AS GoldBadges,
        SUM(CASE 
            WHEN b.Class = 2 THEN 1 
            ELSE 0 
        END) AS SilverBadges,
        SUM(CASE 
            WHEN b.Class = 3 THEN 1 
            ELSE 0 
        END) AS BronzeBadges
    FROM 
        Users ub
    LEFT JOIN 
        Badges b ON ub.Id = b.UserId
    GROUP BY 
        ub.UserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalViews,
    tu.TotalScore,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    TopUsers tu
JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
ORDER BY 
    tu.TotalViews DESC, 
    tu.TotalScore DESC
LIMIT 10;

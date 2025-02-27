WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.UpVotes > p.DownVotes THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        PositiveScorePosts,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) as Rank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
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
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.PositiveScorePosts,
    tu.TotalScore,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    TopUsers tu
JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;

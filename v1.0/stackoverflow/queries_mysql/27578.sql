mysql
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(CASE WHEN p.PostTypeId = 5 THEN 1 ELSE 0 END) AS TotalExcerpts,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(v.BountyAmount) AS AvgBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    WHERE u.Reputation > 50  
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalTagWikis,
        ua.TotalExcerpts,
        ua.TotalScore,
        ua.AvgBounty,
        @rankByScore := IF(@prevScore = ua.TotalScore, @rankByScore, @rowNumber) AS RankByScore,
        @prevScore := ua.TotalScore,
        @rowNumber := @rowNumber + 1 AS rk
    FROM UserActivity ua
    CROSS JOIN (SELECT @rankByScore := 0, @prevScore := NULL, @rowNumber := 1) r
    ORDER BY ua.TotalScore DESC
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalTagWikis,
        TotalExcerpts,
        TotalScore,
        AvgBounty,
        RankByScore,
        DENSE_RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts
    FROM TopUsers
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalTagWikis,
    tu.TotalExcerpts,
    tu.TotalScore,
    tu.AvgBounty,
    tu.RankByScore,
    tu.RankByPosts,
    CASE 
        WHEN tu.RankByScore = tu.RankByPosts THEN 'Equal Ranking'
        WHEN tu.RankByScore < tu.RankByPosts THEN 'Higher Score Rank'
        ELSE 'Higher Post Rank'
    END AS RankingComparison
FROM RankedUsers tu
WHERE tu.RankByScore <= 10 OR tu.RankByPosts <= 10  
ORDER BY tu.TotalScore DESC, tu.TotalPosts DESC;

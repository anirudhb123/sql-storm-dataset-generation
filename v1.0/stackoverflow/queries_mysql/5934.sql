
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        TotalScore, 
        AvgViews, 
        TotalComments,
        @rank := IF(@prev_total_score = TotalScore AND @prev_total_posts = TotalPosts, @rank, @rank + 1) AS Rank,
        @prev_total_score := TotalScore,
        @prev_total_posts := TotalPosts
    FROM UserActivity, (SELECT @rank := 0, @prev_total_score := NULL, @prev_total_posts := NULL) AS vars
    ORDER BY TotalScore DESC, TotalPosts DESC
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalScore,
    tu.AvgViews,
    tu.TotalComments,
    CASE 
        WHEN tu.Rank <= 10 THEN 'Top User' 
        ELSE 'Regular User' 
    END AS UserStatus
FROM TopUsers tu
WHERE tu.TotalPosts > 5 
ORDER BY tu.Rank;

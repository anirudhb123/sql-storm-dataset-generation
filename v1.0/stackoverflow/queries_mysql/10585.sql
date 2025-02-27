
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(p.Score) AS AvgPostScore
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
        AvgPostScore,
        @row_number := IF(@prev_total_posts = TotalPosts, @row_number, @row_number + 1) AS UserRank,
        @prev_total_posts := TotalPosts
    FROM 
        UserPostStats, (SELECT @row_number := 0, @prev_total_posts := NULL) AS vars
    ORDER BY 
        TotalPosts DESC
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    PositiveScorePosts,
    AvgPostScore
FROM 
    TopUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;

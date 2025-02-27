
WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.ViewCount) AS AvgViewsPerPost,
        AVG(p.Score) AS AvgScorePerPost
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),

UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalScore,
        ps.TotalViews,
        ps.AvgViewsPerPost,
        ps.AvgScorePerPost
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)

SELECT 
    u.Id,
    u.DisplayName,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.AvgViewsPerPost, 0.0) AS AvgViewsPerPost,
    COALESCE(ps.AvgScorePerPost, 0.0) AS AvgScorePerPost
FROM 
    UserStats u
ORDER BY 
    TotalPosts DESC
LIMIT 100;

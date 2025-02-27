
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.PostTypeId) AS UniquePostTypes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(TIMESTAMPDIFF(SECOND, p.CreationDate, p.LastActivityDate)) AS AvgPostDurationInSeconds
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
        UniquePostTypes,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        AvgPostDurationInSeconds,
        @rank := IF(@prev_score = TotalScore, @rank, @rank + 1) AS ScoreRank,
        @prev_score := TotalScore
    FROM 
        UserPostStats, (SELECT @rank := 0, @prev_score := NULL) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    UniquePostTypes,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    AvgPostDurationInSeconds,
    ScoreRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10
ORDER BY 
    TotalScore DESC;

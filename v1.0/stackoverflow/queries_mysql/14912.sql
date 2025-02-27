
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        AVG(IFNULL(p.Score, 0)) AS AvgScorePerPost,
        AVG(IFNULL(p.ViewCount, 0)) AS AvgViewsPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionsCount,
    AnswersCount,
    TotalScore,
    TotalViews,
    AvgScorePerPost,
    AvgViewsPerPost
FROM 
    UserPostStats
ORDER BY 
    TotalScore DESC
LIMIT 10;

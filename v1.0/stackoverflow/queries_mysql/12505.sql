
WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    TotalPosts,
    AverageScore,
    TotalViews,
    TotalAnswers,
    @row := @row + 1 AS Rank
FROM 
    PostStats, (SELECT @row := 0) r
ORDER BY 
    TotalPosts DESC;

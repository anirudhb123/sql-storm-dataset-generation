-- Performance benchmarking query to analyze the distribution of posts by type and their average scores

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
    *,
    ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
FROM 
    PostStats
ORDER BY 
    TotalPosts DESC;

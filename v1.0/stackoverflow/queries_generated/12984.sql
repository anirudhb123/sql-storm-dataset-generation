-- Performance benchmarking SQL query to analyze the average score of posts by type and average views of users with badges
WITH PostScoreViews AS (
    SELECT 
        pt.Name AS PostType,
        AVG(p.Score) AS AverageScore,
        AVG(u.Views) AS AverageViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- considers posts created in the last year
    GROUP BY 
        pt.Name
)
SELECT 
    PostType,
    AverageScore,
    AverageViews
FROM 
    PostScoreViews
ORDER BY 
    AverageScore DESC;

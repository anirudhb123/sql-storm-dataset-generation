
WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(TIMESTAMPDIFF(SECOND, p.CreationDate, COALESCE(p.LastActivityDate, CURRENT_TIMESTAMP))) AS AverageActiveDurationInSeconds
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    p.PostType,
    p.TotalPosts,
    p.AverageScore,
    p.TotalViews,
    p.AverageActiveDurationInSeconds,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId IN (SELECT Id FROM Posts WHERE PostTypeId IN (SELECT Id FROM PostTypes WHERE Name = p.PostType))) AS TotalComments
FROM 
    PostStats p
ORDER BY 
    p.TotalPosts DESC;

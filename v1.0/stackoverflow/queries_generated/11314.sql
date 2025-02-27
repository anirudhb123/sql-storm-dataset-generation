-- Performance Benchmarking SQL Query

-- 1. Get the number of posts for each post type
WITH PostTypeCount AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

-- 2. Get the average score of posts by post type
AvgPostScore AS (
    SELECT 
        pt.Name AS PostTypeName,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

-- 3. Get the total number of comments for each post type
CommentCount AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

-- Final Result Set - Performance metrics for post types
SELECT 
    ptc.PostTypeName,
    ptc.PostCount,
    aps.AverageScore,
    cc.CommentCount
FROM 
    PostTypeCount ptc
JOIN 
    AvgPostScore aps ON ptc.PostTypeName = aps.PostTypeName
JOIN 
    CommentCount cc ON ptc.PostTypeName = cc.PostTypeName
ORDER BY 
    ptc.PostTypeName;

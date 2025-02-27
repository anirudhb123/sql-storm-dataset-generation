-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the count of posts by type, average score of posts, 
-- average answers per question, and total number of users with badges 
-- that are "gold", "silver", or "bronze".

WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType, 
        COUNT(p.Id) AS PostCount, 
        AVG(p.Score) AS AvgScore, 
        AVG(CASE WHEN pt.Id = 1 THEN p.AnswerCount ELSE NULL END) AS AvgAnswersPerQuestion -- Only consider answers for questions
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
BadgeStatistics AS (
    SELECT 
        b.Class,
        COUNT(DISTINCT b.UserId) AS UserCount
    FROM 
        Badges b
    WHERE 
        b.Class IN (1, 2, 3)  -- Only counting gold (1), silver (2), and bronze (3) badges
    GROUP BY 
        b.Class
)

SELECT 
    ps.PostType, 
    ps.PostCount, 
    ps.AvgScore, 
    ps.AvgAnswersPerQuestion,
    COALESCE(bs.UserCount, 0) AS UsersWithBadges
FROM 
    PostStatistics ps
LEFT JOIN 
    BadgeStatistics bs ON ps.PostType = 'Question'  -- Only join badge stats if we are interested in questions
ORDER BY 
    ps.PostType;

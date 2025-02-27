-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the top 10 users with the highest reputation 
-- along with the count of their posts and the total score of their posts.
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id,
        u.DisplayName,
        u.Reputation
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.PostCount,
    ups.TotalScore
FROM 
    UserPostStats ups
ORDER BY 
    ups.Reputation DESC
LIMIT 10;

-- This query analyzes the average score of posts based on their type.
SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;

-- This query counts the number of different post history types applied to posts.
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    HistoryCount DESC;

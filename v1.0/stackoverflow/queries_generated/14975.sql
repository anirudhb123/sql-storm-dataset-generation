-- Performance Benchmarking Query

-- This query retrieves the count of posts, average score, and total views grouped by post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
INNER JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- This query measures the performance of user activity, fetching the total number of users, 
-- average reputation, and total badges received grouped by badge class.
SELECT 
    b.Class AS BadgeClass,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation,
    COUNT(b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    b.Class
ORDER BY 
    BadgeClass ASC;

-- This query determines the distribution of comments by post type, checking how many 
-- comments exist for each type of post in the system:
SELECT 
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
INNER JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    CommentCount DESC;

-- This query evaluates the effectiveness of closing reasons by counting the occurrences 
-- in the post history.
SELECT 
    cht.Name AS CloseReason,
    COUNT(ph.Id) AS CloseCount
FROM 
    PostHistory ph
INNER JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
INNER JOIN 
    CloseReasonTypes cht ON ph.Comment::int = cht.Id
WHERE 
    pht.Id IN (10, 11)  -- Only considering Post Closed and Post Reopened types
GROUP BY 
    cht.Name
ORDER BY 
    CloseCount DESC;

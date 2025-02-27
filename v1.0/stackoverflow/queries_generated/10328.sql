-- Performance benchmarking query for the Stack Overflow schema

-- Analyzing user engagement on posts, by counting answers and comments for each user
SELECT
    u.Id AS UserId,
    u.DisplayName,
    COUNT(a.Id) AS TotalAnswers,
    COUNT(c.Id) AS TotalComments,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.Score) AS TotalScore
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1 -- Counting answers for questions
LEFT JOIN
    Comments c ON p.Id = c.PostId
WHERE
    u.Reputation > 0 -- Considering only users with reputation
GROUP BY
    u.Id, u.DisplayName
ORDER BY
    TotalAnswers DESC, TotalViews DESC;

-- Query to benchmark the performance of post history types
SELECT
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount,
    MAX(ph.CreationDate) AS MostRecentAction
FROM
    PostHistory ph
JOIN
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY
    pht.Name
ORDER BY
    HistoryCount DESC;

-- Query to find out the distribution of posts by type
SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY
    pt.Name
ORDER BY
    PostCount DESC;

-- Query to calculate the average reputation of users for each tag
SELECT
    t.TagName,
    AVG(u.Reputation) AS AverageReputation,
    COUNT(p.Id) AS PostCount
FROM
    Tags t
LEFT JOIN
    Posts p ON t.Id = p.TagId
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
GROUP BY
    t.TagName
ORDER BY
    AverageReputation DESC;

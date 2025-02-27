-- Performance Benchmarking Query

-- 1. Get total number of Posts by PostType
SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;

-- 2. Average view count and score for Questions (PostTypeId = 1)
SELECT
    AVG(ViewCount) AS AverageViewCount,
    AVG(Score) AS AverageScore
FROM
    Posts
WHERE
    PostTypeId = 1;

-- 3. Top 10 Users by Reputation
SELECT
    DisplayName,
    Reputation,
    COUNT(p.Id) AS PostsCount
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
GROUP BY
    DisplayName, Reputation
ORDER BY
    Reputation DESC
LIMIT 10;

-- 4. Distribution of Votes by VoteType
SELECT
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM
    Votes v
JOIN
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY
    vt.Name
ORDER BY
    VoteCount DESC;

-- 5. Count of Badges per User
SELECT
    u.DisplayName,
    COUNT(b.Id) AS BadgeCount
FROM
    Users u
LEFT JOIN
    Badges b ON u.Id = b.UserId
GROUP BY
    u.DisplayName
ORDER BY
    BadgeCount DESC;

-- 6. Most active Post Editors
SELECT
    LastEditorDisplayName,
    COUNT(*) AS EditCount
FROM
    Posts
WHERE
    LastEditorUserId IS NOT NULL
GROUP BY
    LastEditorDisplayName
ORDER BY
    EditCount DESC
LIMIT 10;

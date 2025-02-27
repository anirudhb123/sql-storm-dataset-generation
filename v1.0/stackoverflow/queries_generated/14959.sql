-- Performance Benchmarking Query for StackOverflow Schema

-- Calculate the number of posts by type, average score, and the total view count
SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;

-- Benchmark the average time taken for edits by each user
SELECT
    u.DisplayName AS UserName,
    COUNT(ph.Id) AS TotalEdits,
    AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.LastEditDate))) AS AverageTimeToEdit
FROM
    PostHistory ph
JOIN
    Posts p ON ph.PostId = p.Id
JOIN
    Users u ON ph.UserId = u.Id
WHERE
    ph.PostHistoryTypeId IN (4, 5, 6)  -- considering title, body and tags edits
GROUP BY
    u.DisplayName
ORDER BY
    AverageTimeToEdit ASC;

-- Analyze user engagement through votes and comments on posts
SELECT
    u.DisplayName AS UserName,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(p.ViewCount) AS TotalPostViews
FROM
    Users u
LEFT JOIN
    Votes v ON u.Id = v.UserId
LEFT JOIN
    Comments c ON u.Id = c.UserId
LEFT JOIN
    Posts p ON v.PostId = p.Id OR c.PostId = p.Id
GROUP BY
    u.DisplayName
ORDER BY
    TotalVotes DESC, TotalComments DESC;

-- Measure performance of post closures by reason type
SELECT
    crt.Name AS CloseReason,
    COUNT(ph.Id) AS TotalClosures,
    AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.CreationDate))) AS AverageTimeToClose
FROM
    PostHistory ph
JOIN
    Posts p ON ph.PostId = p.Id
JOIN
    CloseReasonTypes crt ON ph.Comment::int = crt.Id  -- assuming comment field holds CloseReasonId
WHERE
    ph.PostHistoryTypeId = 10  -- considering post closure
GROUP BY
    crt.Name
ORDER BY
    TotalClosures DESC;

-- Summary of badge achievements by users
SELECT
    u.DisplayName AS UserName,
    COUNT(b.Id) AS TotalBadges,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM
    Users u
LEFT JOIN
    Badges b ON u.Id = b.UserId
GROUP BY
    u.DisplayName
ORDER BY
    TotalBadges DESC;

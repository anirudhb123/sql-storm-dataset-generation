-- Performance Benchmarking Query

-- This query examines the number of posts, their score, and user reputation to benchmark performance of users based on their contributions.
SELECT
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    SUM(p.Score) AS TotalScore,
    AVG(p.ViewCount) AS AvgViewCount,
    MAX(p.CreationDate) AS LastPostDate
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
GROUP BY
    u.Id, u.DisplayName, u.Reputation
ORDER BY
    TotalScore DESC, PostCount DESC;

-- This query evaluates the performance of posts by their types and how many comments they received.
SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS NumberOfPosts,
    SUM(c.CommentCount) AS TotalComments,
    AVG(p.Score) AS AvgPostScore,
    MAX(p.LastActivityDate) AS LastActivePostDate
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN
    (SELECT PostId, COUNT(Id) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
GROUP BY
    pt.Name
ORDER BY
    TotalComments DESC, AvgPostScore DESC;

-- This query measures the average time taken to receive votes on posts.
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    AVG(v.CreationDate - p.CreationDate) AS AvgTimeToVote
FROM
    Posts p
JOIN
    Votes v ON p.Id = v.PostId
GROUP BY
    p.Id, p.Title, p.CreationDate
ORDER BY
    AvgTimeToVote ASC;

-- This will show the impact of badges on user reputation.
SELECT
    u.Id AS UserId,
    u.DisplayName,
    SUM(b.Class) AS TotalBadgeClass,
    AVG(u.Reputation) AS AvgReputation
FROM
    Users u
JOIN
    Badges b ON u.Id = b.UserId
GROUP BY
    u.Id, u.DisplayName
ORDER BY
    TotalBadgeClass DESC;

-- Performance Benchmarking Query: Get metrics on Posts, Votes, and Users
SELECT
    p.PostTypeId,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,
    SUM(v.VoteTypeId = 3) AS TotalDownVotes,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation,
    MIN(p.CreationDate) AS EarliestPostDate,
    MAX(p.CreationDate) AS LatestPostDate
FROM
    Posts p
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
WHERE
    p.CreationDate >= NOW() - INTERVAL '1 YEAR' -- filter for the last year
GROUP BY
    p.PostTypeId
ORDER BY
    TotalPosts DESC;

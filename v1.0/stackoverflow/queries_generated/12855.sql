-- Performance Benchmarking Query

SELECT
    u.Reputation AS UserReputation,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    MAX(b.Date) AS LastBadgeDate
FROM
    Users u
JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    Badges b ON u.Id = b.UserId
WHERE
    p.CreationDate > '2023-01-01' -- Filter for posts created after January 1, 2023
GROUP BY
    u.Id, p.Id
ORDER BY
    PostScore DESC, PostViewCount DESC, UserReputation DESC
LIMIT 100; -- Limit results to top 100 entries

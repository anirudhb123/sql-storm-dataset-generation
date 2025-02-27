-- Performance Benchmarking Query
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    ut.Name AS PostTypeName,
    p.LastActivityDate
FROM
    Posts p
JOIN
    Users u ON p.OwnerUserId = u.Id
JOIN
    PostTypes ut ON p.PostTypeId = ut.Id
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
WHERE
    p.CreationDate >= '2023-01-01' -- Benchmarking for posts created this year
GROUP BY
    p.Id, u.DisplayName, ut.Name
ORDER BY
    p.Score DESC, p.ViewCount DESC
LIMIT 100; -- Limit to top 100 posts based on score and view count

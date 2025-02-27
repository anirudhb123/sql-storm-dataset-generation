-- Performance Benchmarking Query
-- This query retrieves statistics on posts and their associated user details,
-- along with the number of comments and votes they have received.

SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Id AS UserId,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes
FROM
    Posts p
JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
GROUP BY
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount,
    p.AnswerCount, p.CommentCount, p.FavoriteCount,
    u.Id, u.DisplayName, u.Reputation
ORDER BY
    p.CreationDate DESC
LIMIT 100; -- Limit to the most recent 100 posts for benchmarking


SELECT
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(IFNULL(p.Score, 0)) AS TotalPostScore,
    SUM(IFNULL(c.Score, 0)) AS TotalCommentScore,
    SUM(IFNULL(b.Class, 0)) AS TotalBadges,
    MAX(p.CreationDate) AS LastPostDate
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Badges b ON u.Id = b.UserId
GROUP BY
    u.Id, u.DisplayName, u.Reputation, p.CreationDate
ORDER BY
    TotalPosts DESC
LIMIT 100;

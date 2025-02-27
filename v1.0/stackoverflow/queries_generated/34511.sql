WITH RecursivePostHierarchy AS (
    SELECT Id AS PostId, Title, ParentId, CreationDate, Score, OwnerUserId,
           0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id AS PostId, p.Title, p.ParentId, p.CreationDate, p.Score, p.OwnerUserId,
           Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserStatistics AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COUNT(DISTINCT p.Id) AS PostCount,
           COUNT(DISTINCT c.Id) AS CommentCount,
           SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
           AVG(COALESCE(v.BountyAmount, 0)) AS AvgBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PopularTags AS (
    SELECT Tags.TagName,
           COUNT(p.Id) AS PostCount
    FROM Posts p
    CROSS JOIN LATERAL string_to_array(p.Tags, ',') AS Tags(TagName)
    GROUP BY Tags.TagName
    ORDER BY PostCount DESC
    LIMIT 5
)
SELECT u.DisplayName,
       u.Reputation,
       us.PostCount,
       us.CommentCount,
       us.TotalBounty,
       us.AvgBounty,
       pt.TagName,
       pt.PostCount AS PopularPostCount,
       (SELECT COUNT(*) FROM Posts p2 WHERE p2.OwnerUserId = u.Id AND p2.Score > 0) AS PositiveScorePosts,
       (SELECT COUNT(*) FROM Posts p3 WHERE p3.OwnerUserId = u.Id AND p3.Score < 0) AS NegativeScorePosts,
       ph.PostId AS HierarchyPostId,
       ph.Title AS HierarchyTitle,
       ph.Level
FROM UserStatistics us
JOIN Users u ON us.UserId = u.Id
LEFT JOIN PopularTags pt ON us.PostCount > 0
LEFT JOIN RecursivePostHierarchy ph ON ph.OwnerUserId = u.Id AND ph.Level = 0
WHERE u.Reputation > 1000
ORDER BY u.Reputation DESC, us.PostCount DESC;

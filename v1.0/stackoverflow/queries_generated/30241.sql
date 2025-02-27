WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, IsModeratorOnly, IsRequired, 0 AS Level
    FROM Tags
    WHERE IsRequired = 1

    UNION ALL

    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, t.IsModeratorOnly, t.IsRequired, r.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy r ON t.Id = r.Id
    WHERE r.Level < 10 -- Limit recursion depth to prevent infinite loops
), 

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT v.Id) AS VotesCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
), 

PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    th.TagName AS PopularTag,
    pp.Title AS TopPost,
    pp.Score AS TopPostScore
FROM UserActivity u
LEFT JOIN PopularPosts pp ON pp.PostRank = 1
LEFT JOIN RecursiveTagHierarchy th ON th.Id = pp.Id
WHERE u.Reputation > 1000
  AND pp.Score IS NOT NULL
  AND th.IsModeratorOnly = 0
ORDER BY u.Reputation DESC, pp.Score DESC;

In this SQL query:

1. **Recursive CTE (Common Table Expressions)** is used to define a hierarchy of required tags from the `Tags` table.
2. We created a `UserActivity` CTE to aggregate user activity data including post count, comment count, and vote count.
3. The `PopularPosts` CTE retrieves posts created in the last year, ordering them by score and assigning a rank.
4. The final selection gathers user data, their most popular tag, and the top-ranked post while applying complex predicates to filter results. 
5. Utilizes `LEFT JOIN` and aggregates to ensure we capture all necessary details.

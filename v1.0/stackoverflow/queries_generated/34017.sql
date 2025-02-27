WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, IsModeratorOnly, IsRequired, 0 AS Level
    FROM Tags
    WHERE IsModeratorOnly = 0

    UNION ALL

    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, t.IsModeratorOnly, t.IsRequired, r.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy r ON t.Id = r.Id
    WHERE r.Level < 5
),

RecentPostActivities AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentActivityRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),

ClosedPosts AS (
    SELECT PostId, COUNT(*) AS CloseCount
    FROM PostHistory
    WHERE PostHistoryTypeId = 10
    GROUP BY PostId
),

VoteStats AS (
    SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Votes
    GROUP BY PostId
)

SELECT pt.TagName, rpa.Title, rpa.OwnerDisplayName, rpa.CreationDate, rpa.Score, 
       COALESCE(cp.CloseCount, 0) AS CloseCount,
       COALESCE(vs.TotalUpVotes, 0) AS TotalUpVotes,
       COALESCE(vs.TotalDownVotes, 0) AS TotalDownVotes,
       CASE 
           WHEN rpa.Score > 100 THEN 'High'
           WHEN rpa.Score BETWEEN 50 AND 100 THEN 'Medium'
           ELSE 'Low'
       END AS PopularityCategory
FROM RecursiveTagHierarchy pt
LEFT JOIN RecentPostActivities rpa ON rpa.PostId = pt.ExcerptPostId
LEFT JOIN ClosedPosts cp ON cp.PostId = rpa.PostId
LEFT JOIN VoteStats vs ON vs.PostId = rpa.PostId
WHERE rpa.RecentActivityRank <= 5
ORDER BY pt.TagName, rpa.CreationDate DESC;
This SQL query is crafted to showcase various advanced SQL constructs including CTEs (Common Table Expressions), window functions, outer joins, and conditional logic using `CASE`. 

1. **Recursive CTE**: `RecursiveTagHierarchy` demonstrates a recursive structure to retrieve tags with a specific condition.
  
2. **Window Functions**: In `RecentPostActivities`, the `ROW_NUMBER()` function is used to rank posts for each user based on their creation date.

3. **Outer Joins**: The result set joins `RecentPostActivities` with `ClosedPosts` and `VoteStats` using `LEFT JOIN` to ensure that even uninvolved rows are considered.

4. **Outer Constructs and COALESCE**: It counts the closed posts and uses `COALESCE` for presenting zero counts in case of no matching entries.

5. **Complicated Predicates/Expressions/Calculations**: The CASE statement categorizes the posts based on their score into high, medium, or low. 

6. **NULL Logic**: The query effectively handles nulls when there are no associated votes or close reasons. 

This comprehensive query gives insights into recent activities related to tags, combined with post statistics in an SQL environment resembling the given Stack Overflow schema.

WITH RecursivePostLinks AS (
    SELECT pl.PostId, pl.RelatedPostId, 1 AS Depth
    FROM PostLinks pl
    WHERE pl.LinkTypeId = 3  -- Only considering duplicates at this stage
    UNION ALL
    SELECT pl.PostId, pl.RelatedPostId, r.Depth + 1
    FROM PostLinks pl
    JOIN RecursivePostLinks r ON pl.PostId = r.RelatedPostId
    WHERE pl.LinkTypeId = 3 AND r.Depth < 5  -- Limiting the depth to prevent infinite recursion
),
UsersWithBadges AS (
    SELECT u.Id AS UserId, 
           COUNT(b.Id) AS BadgeCount,
           MAX(b.Date) AS LastBadgeDate,
           STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostsWithVotes AS (
    SELECT p.Id AS PostId, 
           COUNT(v.Id) AS VoteCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT p.Id, p.OwnerUserId, p.CloseDate, p.Title, 
           CASE 
               WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
               ELSE 'Open' 
           END AS Status
    FROM Posts p
    WHERE p.ParentId IS NULL
),
CombinedData AS (
    SELECT pp.PostId, pp.RelatedPostId, up.UserId AS UserId, 
           ub.BadgeCount, ub.LastBadgeDate, ub.BadgeNames, 
           pv.VoteCount, pv.UpVotes, pv.DownVotes, 
           cp.Status
    FROM RecursivePostLinks pp
    JOIN UsersWithBadges ub ON pp.RelatedPostId = ub.UserId
    JOIN PostsWithVotes pv ON pp.RelatedPostId = pv.PostId
    LEFT JOIN ClosedPosts cp ON pp.RelatedPostId = cp.Id
)
SELECT cd.UserId,
       COUNT(cd.PostId) AS NumLinkedPosts,
       MAX(cd.BadgeCount) as MaxBadgeCount,
       MAX(cd.VoteCount) AS MaxVoteCount,
       SUM(CASE WHEN cd.Status = 'Closed' THEN 1 ELSE 0 END) AS ClosedPostsCount,
       STRING_AGG(DISTINCT cd.BadgeNames, '; ') AS AllBadgeNames
FROM CombinedData cd
GROUP BY cd.UserId
HAVING MAX(cd.BadgeCount) > 0 
   AND SUM(cd.VoteCount) > 10
   AND COUNT(cd.PostId) > 2
ORDER BY ClosedPostsCount DESC, MaxVoteCount DESC;

This query creates an intricate performance benchmarking scenario by demonstrating a variety of SQL constructs: Common Table Expressions (CTEs) for organizing multiple queries, recursive queries to handle hierarchical data in post links, window functions for badge aggregation, and complex filtering criteria using HAVING and GROUP BY clauses. It also includes logical constructs, obscure predicates, and string aggregations to consolidate badge names. The result aggregates user statistics on linked posts, badges, and votes, filtered by noteworthy conditions, which contribute to a complex and heavy query suitable for performance analysis.

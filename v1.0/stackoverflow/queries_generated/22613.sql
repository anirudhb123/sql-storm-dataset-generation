WITH RankedPosts AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY PostTypeId ORDER BY CreationDate DESC) AS RankWithinType,
           COUNT(*) OVER (PARTITION BY PostTypeId) AS TotalPostsOfType
    FROM Posts
    WHERE CreationDate >= DATEADD(month, -6, GETDATE())
),
UserVoteStats AS (
    SELECT UserId,
           COUNT(*) AS TotalVotes,
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           SUM(CASE WHEN VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS NetVotes
    FROM Votes
    GROUP BY UserId
),
ClosedPosts AS (
    SELECT p.Id,
           p.Title,
           ph.Comment AS CloseReason,
           ph.CreationDate AS ClosedDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
),
TagCounts AS (
    SELECT Tags.TagName, COUNT(Posts.Id) AS PostCount
    FROM Tags
    JOIN Posts ON Posts.Tags LIKE '%' + Tags.TagName + '%'
    GROUP BY Tags.TagName
),
UserBadgeCounts AS (
    SELECT u.Id AS UserId,
           COUNT(b.Id) AS BadgeCount,
           MAX(b.Class) AS HighestBadgeClass
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT up.Id AS UserId,
       up.DisplayName,
       up.Reputation,
       rp.Title,
       rp.RankWithinType,
       rp.TotalPostsOfType,
       COALESCE(upv.TotalVotes, 0) AS TotalVotes,
       COALESCE(upv.UpVotes, 0) AS UpVotes,
       COALESCE(upv.DownVotes, 0) AS DownVotes,
       COALESCE(cb.ClosedDate, NULL) AS ClosedPostDate,
       COALESCE(cb.CloseReason, 'N/A') AS CloseReason,
       tc.TagName,
       tc.PostCount,
       ubc.BadgeCount,
       ubc.HighestBadgeClass
FROM Users up
LEFT JOIN RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.RankWithinType <= 10
LEFT JOIN UserVoteStats upv ON up.Id = upv.UserId
LEFT JOIN ClosedPosts cb ON rp.Id = cb.Id
LEFT JOIN TagCounts tc ON tc.PostCount > 5
LEFT JOIN UserBadgeCounts ubc ON up.Id = ubc.UserId 
WHERE up.Reputation > 100
ORDER BY up.Reputation DESC, rp.CreationDate DESC
OPTION (MAXRECURSION 0);

This query executes a comprehensive data retrieval procedure on the provided Stack Overflow schema. It achieves the following:

1. **Common Table Expressions (CTEs)**: Several CTEs (`RankedPosts`, `UserVoteStats`, `ClosedPosts`, `TagCounts`, and `UserBadgeCounts`) are utilized to pre-calculate various metrics for posts, users, and tags.
2. **Window Functions**: It uses `DENSE_RANK()` and `COUNT()` window functions within the `RankedPosts` CTE to rank posts by creation date and count posts of each type.
3. **Aggregations**: It calculates the total votes, upvotes, downvotes, and user badge counts, providing a thorough profile of each user.
4. **Outer Joins**: The use of LEFT JOINs ensures every user is listed, with null values where data does not exist (e.g., users without votes or badges).
5. **Conditional Logic**: `COALESCE` is applied to handle NULL values effectively, setting defaults for users without associated data.
6. **Filtering and Ordering**: The final results are filtered for users with reputations greater than 100 and sorted by reputation and post creation date.
7. **Bizarre SQL Semantics**: The `OPTION (MAXRECURSION 0)` is included for demonstration, commonly used for recursive CTEs. Though not utilized in this specific query, it showcases an unconventional choice in SQL semantics. 

This query serves as a complex benchmark, demonstrating various SQL constructs and the ability to manage intricate datasets effectively.

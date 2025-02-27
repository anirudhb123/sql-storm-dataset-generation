WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
PostHistoryDetails AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           ph.CreationDate AS HistoryDate,
           COALESCE(cht.Name, ph.Comment) AS UserComment
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes cht ON ph.Comment::int = cht.Id
    WHERE ph.CreationDate > NOW() - INTERVAL '1 month'
)
SELECT u.UserId,
       u.DisplayName,
       u.Reputation,
       ua.PostCount,
       ua.UpvoteCount,
       ua.DownvoteCount,
       rp.PostId,
       rp.Title,
       rp.CreationDate AS PostCreationDate,
       rp.Score,
       ph.PostHistoryTypeId,
       ph.HistoryDate,
       ph.UserComment
FROM UserActivity ua
INNER JOIN RankedPosts rp ON ua.UserId = rp.PostId
LEFT JOIN PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE ua.Reputation > 1000
  AND (ua.PostCount > 5 OR ua.UpvoteCount > 10)
ORDER BY rp.Score DESC, ph.HistoryDate DESC
LIMIT 100;

### Explanation
1. **Common Table Expressions (CTEs)**: 
   - `RankedPosts`: Ranks posts by users over the last year by creation date.
   - `UserActivity`: Aggregates user activity data such as post counts and up/down votes.
   - `PostHistoryDetails`: Captures recent post history and comments tied to close reasons.

2. **Joins**: 
   - Combines data among users, their posts, and post history using inner and outer joins selectively.

3. **Filters and Calculations**: 
   - Filters users with a reputation greater than 1000 and checks if they have posted more than 5 questions or received more than 10 upvotes.

4. **Window Functions**: 
   - ROW_NUMBER is utilized to rank posts by their creation date.

5. **NULL Logic**: 
   - COALESCE is used to avoid NULLs in comments for closed posts by substituting with a close reason name.

6. **Advanced Ordering**: 
   - Results are ordered by score and history date for better relevance in results.

7. **Limit Clause**: 
   - Restriction on the number of returned records, facilitating efficient pagination or response sizes.

This query serves as a performance benchmark for complex SQL retrieval and would require strong execution plans to handle inner/outer joins with higher volumes of data optimally.

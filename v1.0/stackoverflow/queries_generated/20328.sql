WITH RecursiveVotes AS (
    SELECT v.PostId, v.VoteTypeId, COUNT(*) OVER (PARTITION BY v.PostId ORDER BY v.VoteTypeId) AS VoteCount
    FROM Votes v
    WHERE v.CreationDate >= NOW() - INTERVAL '1 year'
),
PostScoreCTE AS (
    SELECT p.Id AS PostId,
           p.Title,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 END), 0) AS NetScore,
           COALESCE(c.CommentCount, 0) AS TotalComments,
           COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges
    FROM Posts p
    LEFT JOIN RecursiveVotes rv ON p.Id = rv.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id, p.Title
),
RankedPosts AS (
    SELECT ps.PostId,
           ps.Title,
           ps.NetScore,
           ps.TotalComments,
           ps.GoldBadges,
           RANK() OVER (ORDER BY ps.NetScore DESC) AS ScoreRank
    FROM PostScoreCTE ps
    WHERE ps.NetScore > 0
)
SELECT r.PostId, 
       r.Title,
       r.NetScore,
       r.TotalComments,
       r.GoldBadges,
       CASE 
           WHEN r.ScoreRank <= 10 THEN 'Top 10 Post'
           WHEN r.ScoreRank > 10 AND r.ScoreRank <= 50 THEN 'Popular Post'
           ELSE 'Less Popular Post'
       END AS Popularity,
       (SELECT STRING_AGG(CONCAT(u.DisplayName, ' (', u.Reputation, ')'), ', ') 
        FROM Users u 
        WHERE u.Id IN (SELECT DISTINCT c.UserId FROM Comments c WHERE c.PostId = r.PostId)) AS Commenters
FROM RankedPosts r
WHERE r.TotalComments > 0
ORDER BY r.NetScore DESC, r.Title;

### Explanation:
1. **CTEs**:
   - `RecursiveVotes`: This CTE counts votes over the last year grouped by post, which could also illustrate how voting patterns change over time.
   - `PostScoreCTE`: It aggregates the posts to calculate their net score and total comments, also counting gold badges for the post owner's user.
   - `RankedPosts`: This ranks the posts based on their net score, focusing on posts with a positive score.

2. **Main Query**: 
   - It selects relevant details about the posts, including a custom label for popularity and a concatenated string of the usernames and reputations of users who commented on each post.

3. **Complex Constructs**:
   - Utilizes window functions to rank posts and aggregate counts while managing potential NULLs with `COALESCE`.
   - Demonstrates the use of subqueries within the SELECT list to gather additional related information (like commenters).
   - String aggregation and concatenation within queries to craft a dynamic response structure.

4. **Conditional Logic**: 
   - Different labels for popularity based on rank provide further insight into post performance dynamically.

This query is designed to benchmark database capabilities in handling multiple joins, CTEs, subquery nesting, and string manipulation while maintaining performance.

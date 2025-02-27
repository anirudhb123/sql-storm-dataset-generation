WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           COALESCE(v.UpVotes, 0) AS UpVotes, 
           COALESCE(v.DownVotes, 0) AS DownVotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
           RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT UserId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY UserId
    ) v ON u.Id = v.UserId
)
SELECT p.Title, 
       p.CreationDate,
       p.Score,
       p.ViewCount,
       p.UpVotes,
       p.DownVotes,
       CASE WHEN p.UserRank = 1 THEN 'Top Post' ELSE 'Regular Post' END AS PostType,
       CASE WHEN p.RecentRank <= 10 THEN 'Recent Hot Post' ELSE NULL END AS HotPostIndicator
FROM RankedPosts p
WHERE p.Score > 0 AND (p.ViewCount > 100 OR (p.UpVotes - p.DownVotes) > 5)
  AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) > 3
  AND (EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = p.OwnerUserId AND b.Class = 1))
  AND (NOT EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 12) AND ph.CreationDate >= NOW() - INTERVAL '6 months'))
ORDER BY p.Score DESC, p.CreationDate ASC
LIMIT 50;

### Explanation of the Query Constructs:

1. **Common Table Expression (CTE)**: The `WITH` clause defines a CTE `RankedPosts` that aggregates necessary data from the `Posts` table, including scores and view counts, while calculating user-specific rankings and recent post rankings using window functions.

2. **Window Functions**: 
   - `ROW_NUMBER()` is used to rank posts per user based on their score (to find the top post).
   - `RANK()` is utilized to give a rank based on the creation date for recently created posts.

3. **Outer Join**: Left join is used to aggregate vote counts from the `Votes` table allowing for posts to exist even if they have no votes.

4. **Correlated Subquery**: The query includes several correlated subqueries to count comments linked to posts, check the existence of badges, and ensure posts have not been recently deleted or closed.

5. **Complex Predicates**: 
   - The `WHERE` clause is set up with intricate conditions involving numerical comparisons, logical combinations, and checks against subqueries. 
   - It ensures to filter out only those posts meeting the criteria of score, view count, comment count, badge status, and non-deletion status within a defined time frame.

6. **NULL Logic**: The use of `COALESCE` ensures that if there are no up or down votes, the DB returns 0 instead of NULL.

7. **String Expressions**: CASE statements are employed to create human-readable indicators based on rankings and criteria matched to define if a post is a 'Top Post' or a potential 'Recent Hot Post'.

8. **Set Operators / Limitations**: The final `SELECT` statement employs `ORDER BY` and `LIMIT` to manage the results effectively, ensuring only the top 50 qualifying posts are returned. 

This query balances complexity with an interesting analysis of posts, taking various factors into consideration for performance benchmarking.

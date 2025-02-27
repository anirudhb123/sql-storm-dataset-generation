WITH Recursive PostDetails AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           COALESCE(
               (SELECT COUNT(*) 
                FROM Comments c 
                WHERE c.PostId = p.Id), 0) AS CommentCount,
           COALESCE(MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteFlag
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY p.Id
),
PostsWithMetrics AS (
    SELECT pd.PostId,
           pd.Title,
           pd.CreationDate,
           pd.Score,
           pd.CommentCount,
           pd.UpVoteFlag,
           ROW_NUMBER() OVER (PARTITION BY pd.UpVoteFlag ORDER BY pd.Score DESC) AS Rank,
           COUNT(CASE WHEN pd.Score > 0 THEN 1 END) OVER () AS PositiveScoreCount,
           COUNT(CASE WHEN pd.Score < 0 THEN 1 END) OVER () AS NegativeScoreCount
    FROM PostDetails pd
),
ClosedPosts AS (
    SELECT ph.PostId,
           ph.CreationDate,
           MIN(ph.CreationDate) AS MinCloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
)
SELECT p.Title,
       p.CreationDate,
       CASE
           WHEN pm.UpVoteFlag = 1 AND pm.Rank <= 5 THEN 'Top Upvoted'
           WHEN cm.CommentCount >= 3 THEN 'Active Discussion'
           WHEN cp.MinCloseDate IS NOT NULL THEN 'Closed Post'
           ELSE 'Standard'
       END AS PostCategory,
       COALESCE(cp.MinCloseDate, 'No Close') AS CloseDate,
       (SELECT COUNT(*) 
        FROM Badges b 
        WHERE b.UserId = p.OwnerUserId) AS BadgeCount
FROM PostsWithMetrics pm
JOIN Posts p ON pm.PostId = p.Id
LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
LEFT JOIN Comments cm ON p.Id = cm.PostId
WHERE (pm.Rank <= 5 OR cm.CommentCount >= 3)
AND COALESCE(pm.PositiveScoreCount, 0) - COALESCE(pm.NegativeScoreCount, 0) > 0
ORDER BY pm.Score DESC, p.CreationDate DESC;

### Explanation of the Query

1. **CTE - Recursive PostDetails**: This CTE aggregates essential post metrics, including comment count, score, and a flag for upvotes.
2. **CTE - PostsWithMetrics**: Computes additional metrics like ranking of posts based on user votes and the positive/negative score counts.
3. **CTE - ClosedPosts**: Identifies closed posts and their earliest close date.
4. **Main SELECT statement**: Pulls relevant data from the `PostsWithMetrics` and joins with the original posts. It categorizes the posts into labels like "Top Upvoted" and "Active Discussion" based on their metrics and checks if they're closed.
5. **NULL Logic**: Utilizes `COALESCE` to handle potential NULLs in the score and close date metrics.
6. **Bizarre SQL Semantics**: Involves several corner cases such as calculating rank based on a flag that groups posts and count measures in an unusual way to get nuanced insights into the posts and their activity.

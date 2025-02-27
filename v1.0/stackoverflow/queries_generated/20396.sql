WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
PostDetails AS (
    SELECT rp.Id, rp.Title, rp.CreationDate, rp.Score, rp.CommentCount, rp.UpvoteCount, rp.DownvoteCount,
           CASE 
               WHEN rp.Score > 0 THEN 'Positive'
               WHEN rp.Score < 0 THEN 'Negative'
               ELSE 'Neutral'
           END AS ScoreType
    FROM RankedPosts rp
    WHERE rp.UserPostRank <= 5
),
RecentBadges AS (
    SELECT b.UserId, STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Date >= NOW() - INTERVAL '1 year'
    GROUP BY b.UserId
),
FilteredPosts AS (
    SELECT pd.*, rb.BadgeNames
    FROM PostDetails pd
    LEFT JOIN RecentBadges rb ON pd.Id = rb.UserId
)
SELECT fp.Id, fp.Title, fp.CreationDate, fp.Score,
       fp.CommentCount, fp.UpvoteCount, fp.DownvoteCount,
       fp.ScoreType, 
       COALESCE(fp.BadgeNames, 'No Badges') AS BadgeInfo
FROM FilteredPosts fp
WHERE fp.ScoreType = 'Positive' AND fp.CommentCount > 0
ORDER BY fp.Score DESC, fp.CreationDate ASC
LIMIT 10;

This query benchmarks performance through the use of several SQL constructs:

1. **Common Table Expressions (CTEs)**: Three CTEs (`RankedPosts`, `PostDetails`, and `RecentBadges`) organize and simplify intermediate computations.
2. **Window Functions**: `ROW_NUMBER()` is used in `RankedPosts` to rank posts per user.
3. **Aggregations with `STRING_AGG`**: This concatenates badge names into a single string per user.
4. **LEFT JOINs**: These ensure posts are shown even if the user has no associated comments or badges.
5. **Complex Predicates**: The final SELECT filters posts that are positively scored, ensuring they have comments while coalescing badge names.
6. **Order by Clause**: Results are sorted first by score and then by creation date, allowing for prioritized display of engaging content.
7. **NULL Handling**: `COALESCE()` is utilized to default to 'No Badges' if no associated badges exist, illustrating how to manage NULL semantics effectively.

The structure produces an interesting report with meaningful data while benchmarking performance through complexity.

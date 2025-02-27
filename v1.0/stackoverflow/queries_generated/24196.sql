WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
           COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
           SUM(COALESCE(v.VoteCount, 0)) OVER (PARTITION BY p.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN (SELECT PostId, COUNT(*) AS VoteCount 
               FROM Votes 
               GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    AND p.ViewCount > 100
), 
ClosedPostDetails AS (
    SELECT ph.PostId,
           ph.Comment,
           ph.CreationDate AS CloseDate,
           p.Title AS ClosedPostTitle,
           ROW_NUMBER() OVER (PARTITION BY ph.UserId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed or reopened
), 
FinalData AS (
    SELECT rp.PostId,
           rp.Title,
           rp.CreationDate,
           rp.CommentCount,
           rp.TotalVotes,
           COALESCE(cp.CloseRank, 0) AS CloseRank,
           STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM RankedPosts rp
    LEFT JOIN ClosedPostDetails cp ON rp.PostId = cp.PostId
    LEFT JOIN Posts p ON rp.PostId = p.Id -- For tags
    LEFT JOIN Tags t ON POSITION(t.TagName IN p.Tags) > 0
    GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.CommentCount, rp.TotalVotes, cp.CloseRank
)
SELECT fd.*, 
       CASE 
           WHEN CloseRank > 0 THEN 'Closed'
           WHEN CommentCount = 0 AND TotalVotes = 0 THEN 'Orphan' 
           ELSE 'Active' 
       END AS PostStatus
FROM FinalData fd
WHERE fd.CommentCount > 0 
ORDER BY TotalVotes DESC, CreationDate ASC
LIMIT 100;

This SQL query performs the following operations:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Gathers posts created in the last year with more than 100 views, ranking them by creation date per user and counting comments and votes.
   - `ClosedPostDetails`: Retrieves details of posts that have been closed or reopened, ranked by the closure date.
   - `FinalData`: Combines ranked posts with closed post details and aggregates tags associated with each post.

2. **Coalesce and String Aggregation**:
   - Tags are aggregated into a comma-separated string for readability. 

3. **CASE Logic**:
   - Categorizes posts as 'Closed', 'Orphan', or 'Active' based on conditions regarding closure status and vote/comment counts.

4. **Outer Join and Grouping**: 
   - Includes LEFT JOINs and aggregates to ensure all posts are represented, whether they have associated comments or tags.

5. **Useful Filtering and Sorting**:
   - Filtering out orphan posts (those with no comments and votes) and sorting the results based on total votes and creation date.

6. **Limit**:
   - Returns only the top 100 results based on the logic outlined. 

This query showcases complex SQL logic with various constructs such as CTEs, window functions, NULL handling, aggregates, and conditional expressions.

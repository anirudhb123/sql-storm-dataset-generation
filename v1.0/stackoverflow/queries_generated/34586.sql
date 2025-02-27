WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),

PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),

PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS RevisionCount,
        MAX(ph.CreationDate) AS LastRevisionDate
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    ph.RevisionCount,
    ph.LastRevisionDate,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top Post'
        WHEN rp.ScoreRank <= 5 THEN 'High Rank'
        ELSE 'Normal Rank'
    END AS RankCategory
FROM RankedPosts rp
LEFT JOIN PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN PostHistories ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 24  -- Suggest Edit Applied
WHERE rp.ViewCount > 100
  AND (rp.Score > 10 OR ph.RevisionCount > 3)
ORDER BY rp.ViewCount DESC, rp.Score DESC
LIMIT 50;


### Explanation:
1. **CTEs (Common Table Expressions)**:
   - `RankedPosts`: Ranks posts of the last year by score, partitioned by post type.
   - `PostVotes`: Aggregates upvotes and downvotes for each post.
   - `PostHistories`: Counts the number of revisions and captures the last revision date for the posts.
  
2. **Main Query**:
   - Joins the results of the three CTEs.
   - Filters posts with more than 100 views and either a score greater than 10 or more than 3 revisions.
   - Categories posts into "Top Post", "High Rank", or "Normal Rank" based on their score rank.
   - Orders by view count and score before limiting the output to the top 50 results.

3. **Use of COALESCE**: Ensures that if there are no votes, it defaults to 0.

4. **Complex predicates**: The query demonstrates various filtering conditions and uses window functions for ranking. 

5. **String expressions and NULL logic**: Incorporates COALESCE to handle NULL values in vote counts.

This query provides a comprehensive snapshot of the performance and popularity of posts while utilizing the provided schema effectively.

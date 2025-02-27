WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ErroneousPosts AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Corresponds to post close, reopen, delete
)
SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    rp.OwnerPostRank,
    ep.Comment AS LastChangeComment
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.Id = pv.PostId
LEFT JOIN 
    ErroneousPosts ep ON rp.Id = ep.PostId AND ep.HistoryRank = 1
JOIN 
    Users u ON rp.OwnerUserId = u.Id
WHERE 
    rp.OwnerPostRank = 1
ORDER BY 
    p.CreationDate DESC 
LIMIT 100;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Ranks posts from users who created them within the last year based on their score.
   - `PostVotes`: Aggregates upvotes and downvotes for each post.
   - `ErroneousPosts`: Gathers posts with significant history events (close, reopen, delete) and ranks by the most recent such event.

2. **Joins**:
   - The main select joins the results from the CTEs to combine ranked posts with their vote counts and any recent significant changes in their status.

3. **Window Functions**:
   - `ROW_NUMBER()` is used to rank posts by scores for each user and to identify the most recent history change for posts.

4. **NULL Logic**:
   - `COALESCE` is employed to handle potential NULL values when calculating upvotes and downvotes.

5. **Complicated Predicates**:
   - The query includes predicates to filter by post history types, focusing on significant changes to posts.

6. **Ordering and Limiting**:
   - The final result is ordered by creation date and limited to 100 records to facilitate performance benchmarking.

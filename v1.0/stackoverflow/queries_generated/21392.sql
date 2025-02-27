WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownvoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId = 10) AS LastCloseDate,
        MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId = 11) AS LastReopenDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerName,
    pvc.UpvoteCount,
    pvc.DownvoteCount,
    pc.CommentCount,
    COALESCE(phd.CloseReopenCount, 0) AS CloseReopenCount,
    phd.LastCloseDate,
    phd.LastReopenDate,
    CASE 
        WHEN rp.RankByScore <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.RankByScore <= 10
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;

### Explanation:
1. **CTEs**: Multiple Common Table Expressions (CTEs) are used for modular logic:
   - `RankedPosts`: Ranks posts by score within their post types created in the last year.
   - `PostVoteCounts`: Counts upvotes and downvotes for each post.
   - `PostComments`: Counts the number of comments per post.
   - `PostHistoryDetails`: Analyzes post history to count close/reopen actions and stores dates of the last close/reopen.
  
2. **LEFT JOINs**: The main query pulls from the ranked posts, linking to user data, vote counts, comment counts, and post history details.

3. **COALESCE**: Used to ensure `CloseReopenCount` defaults to 0 if no history exists.

4. **Case Statement**: Classifies posts as either 'Top Post' or 'Regular Post' based on their rank in the score.

5. **Complexity & Edge Cases**: Incorporates filtering, aggregation, and handling of potential NULL values elegantly to ensure all scenarios are covered, including posts with no votes or comments.

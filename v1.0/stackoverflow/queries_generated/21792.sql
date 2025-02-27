WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, -- Count upvotes
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount -- Count downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Only consider posts from the last year
    GROUP BY 
        p.Id, p.PostTypeId, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COALESCE(MAX(ph.Comment), 'No reason provided') AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseEventRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Filtering to only closed posts
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        cp.CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseEventRank = 1 -- Get the latest close reason if available
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.CloseReason,
    CASE 
        WHEN pd.Score IS NULL THEN 'No Score' 
        WHEN pd.Score > 0 THEN 'Positive' 
        WHEN pd.Score < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS ScoreCategory,
    CASE 
        WHEN pd.CommentCount > 100 THEN 'Highly Discussed Post'
        WHEN pd.CommentCount BETWEEN 50 AND 100 THEN 'Moderately Discussed Post'
        ELSE 'Less Discussed Post'
    END AS DiscussionLevel
FROM 
    PostDetails pd
WHERE 
    pd.CloseReason IS NOT NULL
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC
LIMIT 10;

### Query Explanation:

1. **CTEs (Common Table Expressions)**: 
   - `RankedPosts` calculates ranks based on scores of posts, also aggregating comment counts and up/down votes while filtering for recent posts.
   - `ClosedPosts` fetches information about closed posts with their close reasons and ranks them to get the latest closure event.
   - `PostDetails` combines ranked post data with any related close reasons.

2. **Main SELECT Statement**: 
   - Retrieves details from `PostDetails`, including title, score, view counts, comment counts, upvote and downvote counts, and the close reason.
   - Categorizes the score into "Positive," "Negative," "Neutral," or "No Score."
   - Assigns a discussion level title based on comment activity.

3. **NULL Logic**: Uses `COALESCE` to handle potentially NULL close reasons and a case structure to manage score categorization.

4. **Ordering and Limiting**: The results are sorted based on view counts and scores, showing only the top 10 posts based on defined criteria.

This query intricately joins multiple elements of the schema and showcases powerful SQL functionalities.

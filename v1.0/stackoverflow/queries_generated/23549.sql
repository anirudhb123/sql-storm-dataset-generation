WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
),
FilteredPosts AS (
    SELECT 
        rp.*,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryCreationDate,
        ROW_NUMBER() OVER (PARTITION BY rp.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM RankedPosts rp
    LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
    WHERE ph.PostHistoryTypeId IN (10, 11, 12)  -- Considering only post closure, reopening, and deletion events
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        ViewCount,
        Score
    FROM FilteredPosts
    WHERE ScoreRank <= 10  -- Top 10 posts per type by Score
    AND UserPostRank = 1   -- Only the latest post per user
),
PostStats AS (
    SELECT 
        tp.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,  -- Summing upvotes
        SUM(v.VoteTypeId = 3) AS DownvoteCount  -- Summing downvotes
    FROM TopPosts tp
    LEFT JOIN Comments c ON tp.PostId = c.PostId
    LEFT JOIN Votes v ON tp.PostId = v.PostId
    GROUP BY tp.PostId
),
FinalOutput AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.ViewCount,
        tp.Score,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        CASE 
            WHEN ps.UpvoteCount IS NULL THEN 'No Upvotes' 
            WHEN ps.UpvoteCount = 0 THEN 'Zero Upvotes' 
            ELSE 'Has Upvotes' 
        END AS UpvoteStatus,
        CASE 
            WHEN ps.DownvoteCount IS NULL THEN 'No Downvotes' 
            WHEN ps.DownvoteCount = 0 THEN 'Zero Downvotes' 
            ELSE 'Has Downvotes' 
        END AS DownvoteStatus
    FROM TopPosts tp
    LEFT JOIN PostStats ps ON tp.PostId = ps.PostId
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    ViewCount,
    Score,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    UpvoteStatus,
    DownvoteStatus
FROM FinalOutput
WHERE Score > 0  -- Only show posts with a positive score
ORDER BY Score DESC, CommentCount DESC
LIMIT 50;  -- Limiting to the top 50 results for performance benchmarking

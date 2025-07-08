
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(IF(v.VoteTypeId = 2, v.Id, NULL)) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(IF(v.VoteTypeId = 3, v.Id, NULL)) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 YEAR')
        AND p.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title, 
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    WHERE 
        ph.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 YEAR')
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score'
            WHEN rp.Score > 0 THEN 'Positive'
            WHEN rp.Score < 0 THEN 'Negative'
            ELSE 'Zero Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
),
Combined AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        ps.ScoreCategory,
        COALESCE(cp.CloseReason, 'Not Closed') AS ClosureStatus
    FROM 
        PostStatistics ps
    LEFT JOIN 
        ClosedPosts cp ON ps.PostId = cp.ClosedPostId
)
SELECT 
    *,
    (DownvoteCount * 1.0 / NULLIF(UpvoteCount, 0)) AS DownvoteToUpvoteRatio,
    LEAD(CreationDate) OVER (ORDER BY CreationDate) AS NextPostCreationDate
FROM 
    Combined
WHERE 
    ScoreCategory != 'Zero Score'
ORDER BY 
    Score DESC,
    ClosureStatus ASC
LIMIT 50;

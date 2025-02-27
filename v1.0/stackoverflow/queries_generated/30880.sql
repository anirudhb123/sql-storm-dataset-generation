WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions only
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(b.Date) AS LastBadgeDate
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN Badges b ON b.UserId = p.OwnerUserId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
FinalStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(ps.CommentCount, 0) AS CommentCount,
        COALESCE(ps.VoteCount, 0) AS VoteCount,
        COALESCE(crc.CloseCount, 0) AS CloseCount,
        COALESCE(crc.ReopenCount, 0) AS ReopenCount,
        CASE 
            WHEN rp.Score > 10 THEN 'Hot'
            WHEN rp.Score BETWEEN 5 AND 10 THEN 'Trending'
            ELSE 'Regular'
        END AS PostClassification,
        ps.LastBadgeDate
    FROM RankedPosts rp
    LEFT JOIN PostStats ps ON ps.PostId = rp.PostId
    LEFT JOIN CloseReasonCounts crc ON crc.PostId = rp.PostId
    WHERE rp.PostRank <= 5 -- Only take top 5 posts per user
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.ViewCount,
    f.Score,
    f.CommentCount,
    f.VoteCount,
    f.CloseCount,
    f.ReopenCount,
    f.PostClassification,
    COALESCE(DATEDIFF(NOW(), f.LastBadgeDate), -1) AS DaysSinceLastBadge
FROM FinalStats f
WHERE f.CommentCount > 10 OR f.VoteCount > 5 -- Filter out posts with low engagement
ORDER BY f.Score DESC, f.ViewCount DESC;

WITH UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Votes v
    GROUP BY v.UserId
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId, u.DisplayName
),
RankedPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.OwnerDisplayName,
        pa.CommentCount,
        pa.CloseCount,
        pa.ReopenCount,
        ROW_NUMBER() OVER (ORDER BY pa.CommentCount DESC, pa.CloseCount DESC) AS Rank
    FROM PostAnalytics pa
)
SELECT 
    r.PostId,
    r.Title,
    r.OwnerDisplayName,
    r.CommentCount,
    r.CloseCount,
    r.ReopenCount,
    COALESCE(uvc.Upvotes, 0) AS UserUpvotes,
    COALESCE(uvc.Downvotes, 0) AS UserDownvotes,
    CASE 
        WHEN r.CloseCount > 0 AND r.ReopenCount = 0 THEN 'Closed'
        WHEN r.ReopenCount > 0 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM RankedPosts r
LEFT JOIN UserVoteCounts uvc ON r.OwnerDisplayName = uvc.UserId
WHERE r.Rank <= 10
ORDER BY r.Rank;

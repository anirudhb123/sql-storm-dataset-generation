WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(vt.VoteType, 'None') AS VoteType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseOpenCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Votes vt ON p.Id = vt.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, vt.VoteType
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.VoteType,
        ps.CommentCount,
        ps.CloseOpenCount,
        us.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (ORDER BY ps.ViewCount DESC, ps.CommentCount DESC) AS Rank
    FROM PostStats ps
    JOIN Users us ON ps.OwnerUserId = us.Id
    WHERE ps.PostRank = 1
),
ClosedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory
    WHERE PostHistoryTypeId = 10
    GROUP BY PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.VoteType,
        rp.CommentCount,
        rp.CloseOpenCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        rp.Rank
    FROM RankedPosts rp
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE rp.Rank <= 10
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.VoteType,
    fr.CommentCount,
    fr.CloseOpenCount,
    fr.CloseCount,
    CASE 
        WHEN fr.CloseCount > 1 THEN 'Multiple Closures'
        WHEN fr.CloseCount = 1 THEN 'Single Closure'
        ELSE 'Not Closed'
    END AS ClosureStatus
FROM FinalResults fr
ORDER BY fr.ViewCount DESC, fr.CommentCount DESC;

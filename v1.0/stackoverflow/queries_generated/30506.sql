WITH RECURSIVE UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.CreationDate
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY ph.PostId
),
FinalStatistics AS (
    SELECT
        ua.UserId,
        ua.DisplayName,
        ua.CreationDate,
        ua.PostCount,
        ua.CommentCount,
        ua.Upvotes,
        ua.Downvotes,
        ps.PostId,
        ps.Title,
        ps.CreationDate AS PostCreationDate,
        ps.Score,
        ps.ViewCount,
        cp.CloseCount,
        cp.CloseReasons
    FROM UserActivity ua
    LEFT JOIN PostStatistics ps ON ua.UserId = ps.OwnerUserId
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.PostCount,
    fs.CommentCount,
    fs.Upvotes,
    fs.Downvotes,
    fs.Title,
    fs.PostCreationDate,
    fs.Score,
    fs.ViewCount,
    COALESCE(fs.CloseCount, 0) AS TotalClosedPosts,
    COALESCE(fs.CloseReasons, 'None') AS CloseReasons
FROM FinalStatistics fs
WHERE fs.PostCount > 0
ORDER BY fs.Upvotes DESC, fs.PostCreationDate DESC;

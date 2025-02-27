WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate IS NOT NULL
    GROUP BY p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(CASE WHEN p.LastActivityDate IS NOT NULL THEN 1 ELSE 0 END) AS ActivePosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostClosureReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(*) AS ClosureInstances
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.Comment
),
ResultSet AS (
    SELECT 
        p.PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.UpVotesCount,
        p.DownVotesCount,
        COALESCE(cr.CloseReason, 'No Closure') AS CloseReason,
        COALESCE(cr.ClosureInstances, 0) AS ClosureInstances,
        p.RankByUser,
        ua.TotalPosts,
        ua.TotalBadges,
        ua.ActivePosts,
        CASE 
            WHEN p.RankByUser = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostRank
    FROM RankedPosts p
    JOIN UserActivity ua ON p.OwnerUserId = ua.UserId
    LEFT JOIN PostClosureReasons cr ON p.PostId = cr.PostId
)
SELECT 
    *,
    CASE 
        WHEN ClosureInstances > 0 THEN 'Post has been closed'
        ELSE NULL
    END AS ClosureStatus,
    CASE 
        WHEN RankByUser > 3 THEN 'Not popular enough'
        WHEN RankByUser = 1 AND UpVotesCount > DownVotesCount THEN 'High engagement post'
        ELSE 'Moderately engaged'
    END AS EngagementLevel
FROM ResultSet
ORDER BY CreationDate DESC, UpVotesCount DESC
LIMIT 100 OFFSET 0; 


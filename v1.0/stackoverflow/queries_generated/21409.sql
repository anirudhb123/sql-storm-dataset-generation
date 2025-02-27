WITH UserScore AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        Views,
        UpVotes,
        DownVotes,
        (Views + UpVotes * 2 - DownVotes) AS NetActivityScore
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened' END) AS IsReopened,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndoCount,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (24, 31) THEN ph.Comment END, ', ') AS RecentNotices
    FROM PostHistory ph
    GROUP BY ph.PostId
),
VotesSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 4 THEN 1 END) AS OffensiveCount
    FROM Votes v
    GROUP BY v.PostId
)

SELECT 
    up.UserId,
    u.DisplayName,
    us.Reputation,
    us.NetActivityScore,
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    phs.IsClosed,
    phs.IsReopened,
    phs.DeleteUndoCount,
    vs.UpVoteCount,
    vs.DownVoteCount,
    vs.OffensiveCount,
    CASE 
        WHEN phs.RecentNotices IS NOT NULL THEN phs.RecentNotices 
        ELSE 'No recent notices' 
    END AS RecentNotices,
    CASE 
        WHEN us.Reputation IS NULL AND up.NetActivityScore < 0 THEN 'Unknown User with No Activity'
        ELSE 'User Activity Available'
    END AS User_Activity_Status
FROM RecentPosts pp
INNER JOIN UserScore us ON pp.OwnerUserId = us.UserId
INNER JOIN Users u ON us.UserId = u.Id
LEFT JOIN PostHistorySummary phs ON pp.PostId = phs.PostId
LEFT JOIN VotesSummary vs ON pp.PostId = vs.PostId
WHERE pp.PostRank = 1 
ORDER BY us.NetActivityScore DESC, pp.ViewCount DESC
LIMIT 50;

This query features Common Table Expressions (CTEs) to manage complex subqueries, includes outer joins to aggregate voting behavior, evaluates user activity status with conditional logic, and employs window functions for ranking analysis. Additionally, it demonstrates advanced SQL constructs, such as `STRING_AGG` for summarizing post history comments.

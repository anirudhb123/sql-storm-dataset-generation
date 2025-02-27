WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count of Upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes  -- Count of Downvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
PostHistoryAnalytics AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12)  -- Considering post closure, reopening, and deletion
    GROUP BY ph.PostId
)
SELECT 
    pu.UserId,
    pu.DisplayName,
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    pha.HistoryCount,
    pha.LastActivityDate
FROM RankedUsers pu
LEFT JOIN Posts ps ON pu.UserId = ps.OwnerUserId
LEFT JOIN PostHistoryAnalytics pha ON ps.Id = pha.PostId
WHERE pu.ReputationRank <= 50  -- Only top ranked users
  AND (ps.CommentCount > 0 OR ps.UpVotes > 5)
  AND (pha.HistoryCount IS NULL OR pha.HistoryCount > 1)
ORDER BY pu.Reputation DESC, ps.CreationDate DESC
LIMIT 100;

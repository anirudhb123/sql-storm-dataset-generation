
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount, 
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount 
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL 30 DAY 
    GROUP BY p.Id, p.OwnerUserId
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name SEPARATOR ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastEditedDate,
        COUNT(*) AS ClosureCount 
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13, 14, 15)
    GROUP BY ph.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    rps.PostId,
    rps.CommentCount,
    rps.UpVoteCount,
    rps.DownVoteCount,
    COALESCE(pha.HistoryTypes, 'None') AS PostHistory,
    pha.LastEditedDate,
    pha.ClosureCount,
    CASE 
        WHEN rps.UpVoteCount > rps.DownVoteCount THEN 'Positive Engagement'
        WHEN rps.UpVoteCount < rps.DownVoteCount THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementStatus,
    CASE 
        WHEN up.ReputationRank IS NULL THEN 'No Reputation Rank'
        ELSE CONCAT(up.ReputationRank, ' - ', up.Reputation) 
    END AS UserReputationRank
FROM UserReputation up
LEFT JOIN RecentPostStats rps ON up.UserId = rps.OwnerUserId
LEFT JOIN PostHistoryAggregate pha ON rps.PostId = pha.PostId
WHERE up.CreationDate < NOW() - INTERVAL 1 YEAR 
ORDER BY rps.UpVoteCount DESC, rps.DownVoteCount ASC
LIMIT 100;

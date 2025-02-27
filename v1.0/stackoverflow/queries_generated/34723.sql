WITH RecursivePostChain AS (
    SELECT Id, Title, ParentId, CreationDate, OwnerUserId, 1 AS Level
    FROM Posts
    WHERE PostTypeId = 2 -- Start with Answers

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, p.OwnerUserId, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostChain rpc ON p.Id = rpc.ParentId
), 
UserReputation AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           u.Reputation, 
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId -- Join Users with their Posts
    LEFT JOIN Votes v ON p.Id = v.PostId -- Join with Votes to calculate total bounties 
    GROUP BY u.Id
),
RelevantPosts AS (
    SELECT p.Id, p.Title, p.Score, p.CreationDate, 
           u.DisplayName,
           CASE 
               WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
               WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Answered'
               ELSE 'Open'
           END AS Status
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostHistorySummary AS (
    SELECT ph.PostId, 
           MAX(ph.CreationDate) AS LastChangeDate,
           STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    rp.Title AS PostTitle,
    COALESCE(u.DisplayName, 'Anonymous') AS Owner,
    u.Reputation,
    u.PostCount,
    u.TotalBounty,
    rp.Status AS CurrentStatus,
    rpcs.Level AS AnswerChainLevel,
    phs.LastChangeDate,
    phs.HistoryTypes
FROM RelevantPosts rp
JOIN UserReputation u ON u.UserId = rp.OwnerUserId
LEFT JOIN RecursivePostChain rpcs ON rpcs.ParentId = rp.Id
LEFT JOIN PostHistorySummary phs ON phs.PostId = rp.Id
WHERE u.Reputation >= 500 -- Users with reputation of at least 500
ORDER BY rp.Score DESC, rp.CreationDate DESC
LIMIT 100;

WITH RECURSIVE UserReputationCTE AS (
    SELECT Id, Reputation, DisplayName, 1 AS Level 
    FROM Users 
    WHERE Reputation > 1000
    UNION ALL
    SELECT u.Id, u.Reputation, u.DisplayName, Level + 1
    FROM Users u
    INNER JOIN UserReputationCTE ur ON ur.Reputation < u.Reputation
    WHERE Level < 5
),
PostVoteCounts AS (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(pv.UpVotes, 0) AS UpVotes,
        COALESCE(pv.DownVotes, 0) AS DownVotes,
        p.AskedById,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN PostVoteCounts pv ON p.Id = pv.PostId
    WHERE p.CreationDate >= now() - interval '1 year'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
CombinedMetrics AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.UpVotes,
        pm.DownVotes,
        COALESCE(phd.EditCount, 0) AS EditCount,
        phd.LastEditDate,
        ur.DisplayName AS TopUser,
        ur.Reputation AS TopUserReputation
    FROM PostMetrics pm
    LEFT JOIN PostHistoryDetails phd ON pm.PostId = phd.PostId
    LEFT JOIN UserReputationCTE ur ON pm.AskedById = ur.Id
)
SELECT 
    cm.PostId,
    cm.Title,
    cm.UpVotes,
    cm.DownVotes,
    cm.EditCount,
    cm.LastEditDate,
    CASE 
        WHEN cm.EditCount > 10 THEN 'Highly Edited'
        WHEN cm.EditCount > 5 THEN 'Moderately Edited'
        ELSE 'Rarely Edited'
    END AS EditStatus,
    COALESCE(NULLIF(ur.ProfileImageUrl, ''), 'default_image.png') AS UserProfileImage
FROM CombinedMetrics cm
LEFT JOIN Users ur ON cm.AskedById = ur.Id
WHERE cm.UpVotes - cm.DownVotes > 5
ORDER BY cm.UpVotes DESC, cm.DownVotes ASC
LIMIT 100;

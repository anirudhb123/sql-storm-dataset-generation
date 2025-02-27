
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    WHERE u.LastAccessDate > '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    LIMIT 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        p.Title,
        COALESCE(ph.Comment, 'No Comments') AS UserComment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ph_rn
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 MONTH
)
SELECT
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalVotes,
    u.DisplayName AS OwnerName,
    ph.UserComment,
    ph.CreationDate AS HistoryDate,
    ph.UserDisplayName AS HistoryUser
FROM RecentPosts rp
LEFT JOIN PostVoteStats ps ON rp.Id = ps.PostId
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN PostHistoryDetails ph ON rp.Id = ph.PostId AND ph.ph_rn = 1
WHERE rp.Score > (
    SELECT AVG(Score) FROM Posts WHERE CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
)
ORDER BY rp.CreationDate DESC
LIMIT 100;

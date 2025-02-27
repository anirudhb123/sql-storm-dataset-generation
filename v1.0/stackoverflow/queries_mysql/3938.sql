
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @rank := @rank + 1 AS Rank
    FROM Users u, (SELECT @rank := 0) r
    ORDER BY u.Reputation DESC
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        @post_rank := IF(@prev_owner = p.OwnerUserId, @post_rank + 1, 1) AS PostRank,
        @prev_owner := p.OwnerUserId
    FROM Posts p, Users u, (SELECT @post_rank := 0, @prev_owner := NULL) r
    WHERE p.OwnerUserId = u.Id
    AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
    ORDER BY p.OwnerUserId, p.CreationDate DESC
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason,
        @close_rank := IF(@prev_post = ph.PostId, @close_rank + 1, 1) AS CloseRank,
        @prev_post := ph.PostId
    FROM PostHistory ph, (SELECT @close_rank := 0, @prev_post := NULL) r
    WHERE ph.PostHistoryTypeId = 10
),
VotesSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
CombiningData AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        up.UpVotes,
        up.DownVotes,
        cr.UserDisplayName AS ClosedBy,
        cr.CloseReason,
        ur.Reputation AS UserReputation
    FROM RecentPosts p
    LEFT JOIN VotesSummary up ON p.PostId = up.PostId
    LEFT JOIN ClosedPosts cr ON p.PostId = cr.PostId AND cr.CloseRank = 1
    JOIN UserReputation ur ON p.OwnerDisplayName = ur.DisplayName
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.ViewCount,
    cd.CreationDate,
    COALESCE(cd.UpVotes, 0) AS UpVotes,
    COALESCE(cd.DownVotes, 0) AS DownVotes,
    cd.ClosedBy,
    cd.CloseReason,
    cd.UserReputation,
    CASE WHEN cd.UserReputation > 1000 THEN 'Highly Reputed' 
         WHEN cd.UserReputation BETWEEN 500 AND 1000 THEN 'Moderately Reputed' 
         ELSE 'Needs Attention' END AS ReputationStatus
FROM CombiningData cd
WHERE cd.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 7 DAY)
ORDER BY cd.UserReputation DESC, cd.ViewCount DESC
LIMIT 100;

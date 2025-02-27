
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(u.UpVotes) - SUM(u.DownVotes) AS ReputationScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
HighRepUsers AS (
    SELECT *
    FROM UserActivity
    WHERE ReputationScore > (SELECT AVG(ReputationScore) FROM UserActivity)
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        @rn := IF(@prevOwnerUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevOwnerUserId := p.OwnerUserId
    FROM Posts p, (SELECT @rn := 0, @prevOwnerUserId := NULL) AS vars
    WHERE p.CreationDate > NOW() - INTERVAL 1 YEAR
    ORDER BY p.OwnerUserId, p.CreationDate DESC
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason,
        u.DisplayName AS ClosedBy
    FROM PostHistory ph
    JOIN Users u ON ph.UserId = u.Id
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.CommentCount,
    u.TotalBounty,
    rp.Title,
    rp.CreationDate,
    cp.ClosedDate,
    cp.CloseReason,
    cp.ClosedBy
FROM HighRepUsers u
LEFT JOIN RecentPosts rp ON u.UserId = rp.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.rn = 1
ORDER BY u.ReputationScore DESC, rp.CreationDate DESC
LIMIT 10;

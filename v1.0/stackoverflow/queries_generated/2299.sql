WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- close and reopen actions
    GROUP BY ph.PostId
),
TopUserPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        us.DisplayName,
        us.UpVotes - us.DownVotes AS VoteBalance,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        rp.CreationDate
    FROM RecentPosts rp
    JOIN Users u ON rp.UserId = u.Id
    JOIN UserStats us ON u.Id = us.UserId
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE rp.UserPostRank <= 5
)
SELECT 
    tup.Title,
    tup.DisplayName,
    tup.VoteBalance,
    tup.CloseCount,
    (EXTRACT(EPOCH FROM NOW() - tup.CreationDate) / 3600) AS AgeInHours
FROM TopUserPosts tup
ORDER BY tup.VoteBalance DESC, tup.CloseCount ASC
LIMIT 100;

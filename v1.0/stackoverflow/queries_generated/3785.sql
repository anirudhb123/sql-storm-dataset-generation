WITH UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Votes v
    JOIN Posts p ON v.PostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY v.UserId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 month'
),
ClosedPosts AS (
    SELECT 
        p.Id,
        COUNT(ph.Id) AS CloseCount
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 -- closed posts
    GROUP BY p.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(uvs.UpVotes, 0) AS UpVotes,
    COALESCE(uvs.DownVotes, 0) AS DownVotes,
    COUNT(DISTINCT rp.Id) AS RecentPostCount,
    MAX(cp.CloseCount) AS TotalClosedPosts,
    SUM(CASE WHEN cp.CloseCount > 0 THEN 1 ELSE 0 END) AS ClosedPostsCount
FROM Users u
LEFT JOIN UserVoteStats uvs ON u.Id = uvs.UserId
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN ClosedPosts cp ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = cp.Id)
WHERE u.Reputation > 1000
GROUP BY u.Id, u.DisplayName
ORDER BY UpVotes DESC, RecentPostCount DESC;

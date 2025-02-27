WITH RECURSIVE UserVoteCounts AS (
    SELECT u.Id AS UserId, 
           u.DisplayName,
           COUNT(v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostScore AS (
    SELECT p.Id AS PostId,
           p.Title,
           COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetScore,
           p.CreationDate,
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (ORDER BY (COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0)) DESC) AS RowNum
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  -- Only Questions
),
TopUsers AS (
    SELECT u.UserId,
           u.DisplayName,
           u.Reputation,
           RANK() OVER (ORDER BY uc.VoteCount DESC) AS UserRank
    FROM UserVoteCounts uc
    JOIN Users u ON uc.UserId = u.Id
    WHERE uc.VoteCount > 0
),
RecentPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRow
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT ph.PostId, 
           MIN(ph.CreationDate) AS ClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT pu.UserRank,
       pu.DisplayName AS TopUser,
       ps.Title AS TopPostTitle,
       ps.NetScore AS TopPostScore,
       rp.Title AS RecentPostTitle,
       cp.ClosedDate AS PostClosedDate
FROM TopUsers pu
INNER JOIN PostScore ps ON pu.UserId = ps.OwnerDisplayName
LEFT JOIN RecentPosts rp ON ps.OwnerUserId = rp.OwnerUserId AND rp.RecentPostRow = 1
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
WHERE pu.UserRank <= 10
ORDER BY ps.NetScore DESC;

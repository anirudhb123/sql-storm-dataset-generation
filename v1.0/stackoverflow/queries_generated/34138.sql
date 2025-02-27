WITH RECURSIVE UserRankings AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        1 AS Level
    FROM Users u
    WHERE u.Reputation IS NOT NULL

    UNION ALL

    SELECT 
        u.Id, 
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        ur.Level + 1
    FROM Users u
    JOIN UserRankings ur ON u.Id <> ur.UserId
    WHERE ur.Level < 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MIN(ph.CreationDate) AS FirstClosedDate 
    FROM PostHistory ph 
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN ph.FirstClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostsCount,
        AVG(UPD.CommentCount) AS AvgComments,
        SUM(UPD.UpVotes) - SUM(UPD.DownVotes) AS NetVotes
    FROM Posts p 
    JOIN RecentPosts UPD ON p.Id = UPD.PostId
    LEFT JOIN ClosedPosts ph ON p.Id = ph.PostId
    GROUP BY p.OwnerUserId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.UserRank,
    ups.TotalPosts,
    ups.ClosedPostsCount,
    ups.AvgComments,
    ups.NetVotes
FROM UserRankings ur
LEFT JOIN UserPostStats ups ON ur.UserId = ups.OwnerUserId
WHERE ur.Level = 1 AND ups.TotalPosts > 0
ORDER BY ur.UserRank;


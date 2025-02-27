WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation, u.CreationDate, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(v.BountyAmount) AS TotalBountyVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId
),
UserPostSummary AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        SUM(pd.CommentCount) AS TotalComments,
        COUNT(pd.PostId) AS TotalPosts,
        SUM(pd.UpVotes) AS TotalUpVotes,
        SUM(pd.DownVotes) AS TotalDownVotes,
        MAX(pd.TotalBountyVotes) AS MaxBountyVotes
    FROM UserMetrics um
    LEFT JOIN PostDetails pd ON um.UserId = pd.OwnerUserId
    GROUP BY um.UserId, um.DisplayName
),
RankedTopUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalComments,
        ups.TotalPosts,
        ups.TotalUpVotes,
        ups.TotalDownVotes,
        ups.MaxBountyVotes,
        DENSE_RANK() OVER (ORDER BY ups.TotalUpVotes DESC, ups.TotalPosts DESC) AS UserRank
    FROM UserPostSummary ups
)
SELECT 
    rtu.DisplayName,
    rtu.TotalPosts,
    rtu.TotalComments,
    rtu.TotalUpVotes,
    rtu.TotalDownVotes,
    rtu.MaxBountyVotes,
    CASE 
        WHEN rtu.TotalUpVotes > 100 THEN 'Super User'
        WHEN rtu.TotalUpVotes BETWEEN 50 AND 100 THEN 'Regular User'
        ELSE 'New User'
    END AS UserCategory,
    pt.Name AS PostTypeName
FROM RankedTopUsers rtu
LEFT JOIN PostTypes pt ON pt.Id = (SELECT TOP 1 PostTypeId FROM Posts p WHERE p.OwnerUserId = rtu.UserId ORDER BY p.CreationDate DESC)
WHERE rtu.UserRank <= 10
ORDER BY rtu.TotalUpVotes DESC, rtu.TotalPosts DESC;

WITH NULLCount AS (
    SELECT 
        SUM(CASE WHEN pp.TotalPosts IS NULL THEN 1 ELSE 0 END) AS NullPostCount
    FROM UserPostSummary pp
)

SELECT 
    COUNT(*) AS TotalUsersWithNoPosts,
    (SELECT NullPostCount FROM NULLCount) AS UsersWithNullPosts
FROM Users
WHERE Id NOT IN (SELECT UserId FROM UserPostSummary)
AND (Reputation IS NULL OR CreationDate IS NULL);

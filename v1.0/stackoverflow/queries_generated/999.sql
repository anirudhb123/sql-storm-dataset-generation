WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.*,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN TotalPosts > 0 THEN 'Active' ELSE 'Inactive' END ORDER BY TotalPosts DESC) AS ActiveRank
    FROM UserActivity ua
    WHERE ua.TotalPosts > 0 OR ua.TotalComments > 0
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.UpVotes,
    tu.DownVotes,
    COALESCE(p.Title, 'No Posts') AS RecentlyActivePostTitle,
    COALESCE(a.CreationDate, 'No Activity') AS LastActivityDate
FROM TopUsers tu
LEFT JOIN (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.CreationDate
    FROM Posts p
    WHERE p.CreationDate = (SELECT MAX(CreationDate) FROM Posts WHERE OwnerUserId = p.OwnerUserId)
) p ON tu.UserId = p.OwnerUserId
LEFT JOIN (
    SELECT 
        c.UserId,
        MAX(c.CreationDate) AS CreationDate
    FROM Comments c
    GROUP BY c.UserId
) a ON tu.UserId = a.UserId
WHERE tu.ActiveRank <= 10
ORDER BY tu.PostRank, tu.UpVotes DESC;

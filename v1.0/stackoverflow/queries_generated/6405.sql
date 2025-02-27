WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        MAX(u.LastAccessDate) AS LastActive
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        TotalBadges,
        LastActive,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC, TotalUpvotes DESC, TotalComments DESC) AS Rank
    FROM UserActivity
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    tu.TotalBadges,
    tu.LastActive
FROM TopUsers tu
WHERE tu.Rank <= 10
ORDER BY tu.TotalPosts DESC;

WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownvotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        PostRank
    FROM UserEngagement
    WHERE PostRank <= 10
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.CommentCount,
    pd.VoteCount,
    CASE
        WHEN pd.VoteCount > 10 THEN 'Highly Voted'
        WHEN pd.VoteCount BETWEEN 5 AND 10 THEN 'Moderate Interest'
        ELSE 'Low Interest' 
    END AS PostInterestLevel
FROM TopUsers tu
INNER JOIN PostDetails pd ON tu.UserId = pd.OwnerUserId
ORDER BY tu.TotalPosts DESC, pd.ViewCount DESC;

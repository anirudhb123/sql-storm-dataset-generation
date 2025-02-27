WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBounty,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalComments DESC) AS UserRank
    FROM 
        UserActivity
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
    GROUP BY 
        p.Id
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalBounty,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes
FROM 
    TopUsers tu
FULL OUTER JOIN 
    PostStats ps ON tu.UserId = ps.PostId
WHERE 
    tu.UserRank <= 10 
    OR ps.RecentPostRank <= 10
ORDER BY 
    tu.TotalBounty DESC NULLS LAST, 
    ps.Score DESC;

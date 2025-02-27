WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class = 1, 0) + COALESCE(b.Class = 2, 0) + COALESCE(b.Class = 3, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalBadges,
        RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 5
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes
FROM 
    TopUsers tu
JOIN 
    RankedPosts p ON tu.UserId = p.OwnerUserId
WHERE 
    p.PostRank <= 3
ORDER BY 
    tu.Reputation DESC,
    p.Score DESC
LIMIT 10;

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS TotalUpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.TotalComments,
    ps.TotalUpVotes,
    ps.TotalDownVotes
FROM 
    PostStats ps
WHERE 
    ps.TotalComments > 0 OR ps.TotalUpVotes > 10
ORDER BY 
    ps.TotalUpVotes DESC, 
    ps.TotalDownVotes ASC;

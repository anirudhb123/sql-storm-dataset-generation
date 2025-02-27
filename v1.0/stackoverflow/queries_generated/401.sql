WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(v.VoteTypeId = 2) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, TotalPosts, TotalComments, TotalUpVotes, TotalDownVotes, Rank
    FROM 
        UserStatistics
    WHERE 
        Rank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.Id
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.CommentCount,
    pd.AverageBounty
FROM 
    TopUsers tu
JOIN PostDetails pd ON tu.UserId = pd.PostId
ORDER BY 
    tu.Rank, pd.ViewCount DESC;

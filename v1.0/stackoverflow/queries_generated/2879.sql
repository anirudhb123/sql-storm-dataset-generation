WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
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
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        COALESCE(SUM(rp.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(rp.UpVoteCount), 0) AS TotalUpVotes,
        COALESCE(SUM(rp.DownVoteCount), 0) AS TotalDownVotes
    FROM 
        UserReputation ur
    LEFT JOIN 
        RecentPosts rp ON ur.UserId = rp.OwnerUserId
    WHERE 
        ur.Rank <= 10
    GROUP BY 
        ur.UserId, ur.DisplayName, ur.Reputation
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    CASE 
        WHEN tu.Reputation > 1000 THEN 'High Reputation'
        WHEN tu.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    TopUsers tu
ORDER BY 
    tu.Reputation DESC;

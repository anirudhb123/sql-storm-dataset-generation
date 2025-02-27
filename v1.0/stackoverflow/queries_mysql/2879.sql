
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Users u, (SELECT @row_number := 0) AS rn
    ORDER BY 
        u.Reputation DESC
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate
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

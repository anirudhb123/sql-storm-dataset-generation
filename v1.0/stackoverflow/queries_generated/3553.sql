WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        (SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3)) AS NetVotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalComments,
        ps.NetVotes,
        ps.CreationDate,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
    JOIN 
        PostStatistics ps ON ur.UserId = ps.OwnerUserId
    WHERE 
        ur.Reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalComments,
    tu.NetVotes,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = tu.UserId AND AcceptedAnswerId IS NOT NULL) AS AcceptedAnswers,
    COALESCE(MAX(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS HasClosedPosts
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
WHERE 
    tu.UserRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.TotalComments, tu.NetVotes
ORDER BY 
    tu.Reputation DESC;

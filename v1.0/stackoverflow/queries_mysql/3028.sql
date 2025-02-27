
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(p.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.ViewCount) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        *,
        CASE 
            WHEN Reputation < 10000 THEN 'Moderate'
            WHEN Reputation BETWEEN 10000 AND 50000 THEN 'High'
            ELSE 'Elite'
        END AS ReputationCategory
    FROM 
        UserStats
    WHERE 
        Rank <= 5
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.UpVotes - tu.DownVotes AS NetVotes,
    tu.ReputationCategory,
    COALESCE(GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', '), 'No Tags') AS TagsUsed
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    (SELECT 
         p.Id AS PostId, 
         DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
     INNER JOIN 
         Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON t.PostId = p.Id
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.PostCount, tu.UpVotes, tu.DownVotes, tu.ReputationCategory
ORDER BY 
    tu.Reputation DESC, NetVotes DESC;

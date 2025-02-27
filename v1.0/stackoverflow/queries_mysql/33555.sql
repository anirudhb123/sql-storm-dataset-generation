
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        CAST(u.Reputation AS SIGNED) AS AccumulatedReputation,
        0 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 0

    UNION ALL

    SELECT 
        u.Id, 
        u.Reputation,
        ur.AccumulatedReputation + u.Reputation,
        Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE ur ON u.Id = ur.UserId
    WHERE 
        Level < 3
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ur.AccumulatedReputation, 0) AS TotalReputation,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    CASE 
        WHEN COUNT(p.Id) > 0 THEN 
            ROUND(SUM(p.Score) / COUNT(p.Id), 2)
        ELSE 
            0
    END AS AveragePostScore,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT 
        p.Id, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) TagName 
    FROM 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) t ON TRUE
LEFT JOIN 
    UserReputationCTE ur ON u.Id = ur.UserId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, ur.AccumulatedReputation
ORDER BY 
    TotalReputation DESC
LIMIT 10;

WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserReputation AS (
    SELECT 
        UserId, 
        SUM(Reputation) AS TotalReputation
    FROM 
        Users
    GROUP BY 
        UserId
)
SELECT 
    p.PostTypeId,
    p.PostCount,
    ur.TotalReputation
FROM 
    PostCounts p
JOIN 
    UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE PostTypeId = p.PostTypeId LIMIT 1)
ORDER BY 
    p.PostTypeId;

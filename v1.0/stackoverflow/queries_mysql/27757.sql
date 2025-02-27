
WITH FrequentTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS Tag
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 AS n
         FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
             UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
             UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) n
    ON 
        n.n <= CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1
    WHERE 
        PostTypeId = 1  
),
TagUsage AS (
    SELECT 
        Tag, 
        COUNT(*) AS UsageCount
    FROM 
        FrequentTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        u.Id, u.Reputation
),
CombinedData AS (
    SELECT 
        tr.Tag,
        ur.UserId,
        ur.Reputation,
        ur.PostCount
    FROM 
        TagUsage tr
    CROSS JOIN 
        UserReputation ur
)
SELECT 
    Tag,
    COUNT(DISTINCT UserId) AS UserCount,
    AVG(Reputation) AS AverageReputation,
    SUM(PostCount) AS TotalPosts
FROM 
    CombinedData
GROUP BY 
    Tag
ORDER BY 
    UserCount DESC;

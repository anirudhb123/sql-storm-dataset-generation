
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS TagsSplit
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.TotalScore,
        ur.PostCount,
        ROW_NUMBER() OVER (ORDER BY ur.TotalScore DESC) AS ActiveRank
    FROM 
        UserReputation ur
    WHERE 
        ur.PostCount > 5
)
SELECT 
    tt.TagName,
    tt.PostCount,
    au.DisplayName AS TopUser,
    au.TotalScore
FROM 
    TopTags tt
JOIN 
    ActiveUsers au ON au.ActiveRank <= 10
ORDER BY 
    tt.PostCount DESC, au.TotalScore DESC;

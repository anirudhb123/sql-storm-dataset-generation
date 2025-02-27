
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN (
        SELECT 
            1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
            UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
            -- Adjust the number based on the maximum number of tags.
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagCounts, (SELECT @rownum := 0) r
    ORDER BY 
        PostCount DESC
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
        @activerow := @activerow + 1 AS ActiveRank
    FROM 
        UserReputation ur, (SELECT @activerow := 0) ar
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

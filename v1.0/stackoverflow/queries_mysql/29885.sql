
WITH TagCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1))
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate >= NOW() - INTERVAL 1 YEAR  
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagCounts tc,
        (SELECT @rank := 0) r
    WHERE 
        tc.PostCount > 5  
    ORDER BY 
        tc.PostCount DESC
),
TopUsers AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.QuestionCount,
        au.TotalBounty,
        @rank2 := @rank2 + 1 AS Rank
    FROM 
        ActiveUsers au,
        (SELECT @rank2 := 0) r
    WHERE 
        au.QuestionCount > 0
    ORDER BY 
        au.QuestionCount DESC
)
SELECT 
    t.TagName,
    t.PostCount,
    u.DisplayName AS TopUser,
    u.QuestionCount,
    u.TotalBounty
FROM 
    TopTags t
LEFT JOIN 
    TopUsers u ON u.Rank = 1  
ORDER BY 
    t.PostCount DESC, u.TotalBounty DESC;

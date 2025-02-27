
WITH TagsSplit AS (
    SELECT 
        Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', n.n), '><', -1) AS Tag
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
    ON 
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1  
),

GroupedTags AS (
    SELECT 
        Tag,
        COUNT(PostId) AS PostCount
    FROM 
        TagsSplit
    GROUP BY 
        Tag
    HAVING 
        COUNT(PostId) > 10  
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
                  AND p.PostTypeId = 1  
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        QuestionCount DESC
    LIMIT 5  
),

UserTags AS (
    SELECT 
        u.Id AS UserId,
        ts.Tag,
        COUNT(ts.Tag) AS TagCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    JOIN 
        TagsSplit ts ON p.Id = ts.PostId
    GROUP BY 
        u.Id, ts.Tag
)

SELECT 
    u.DisplayName,
    u.QuestionCount,
    u.TotalBounty,
    GROUP_CONCAT(DISTINCT CONCAT(ut.Tag, ' (', ut.TagCount, ')') ORDER BY ut.Tag SEPARATOR ', ') AS PopularTags
FROM 
    TopUsers u
LEFT JOIN 
    UserTags ut ON u.UserId = ut.UserId
LEFT JOIN 
    GroupedTags g ON ut.Tag = g.Tag
GROUP BY 
    u.UserId, u.DisplayName, u.QuestionCount, u.TotalBounty
ORDER BY 
    u.QuestionCount DESC;

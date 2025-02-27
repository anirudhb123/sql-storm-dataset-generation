
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
        UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
        UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        ub.BadgeCount,
        @rownum := @rownum + 1 AS UserRank
    FROM 
        Users u
    JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    CROSS JOIN (SELECT @rownum := 0) r
    WHERE 
        u.Reputation > 1000
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName AS TopUserName,
    tu.Reputation AS TopUserReputation,
    pt.Tag AS PopularTag,
    pt.TagCount AS PopularTagCount
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON pt.Tag IN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) 
        FROM 
            Posts p 
        INNER JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
            UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
            UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
            UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        WHERE 
            p.OwnerUserId = tu.Id
    )
ORDER BY 
    tu.Reputation DESC, 
    pt.TagCount DESC;

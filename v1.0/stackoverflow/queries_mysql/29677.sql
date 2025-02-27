
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH '<>' FROM Tags), '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                 SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                 SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(TRIM(BOTH '<>' FROM Tags)) - 
                 CHAR_LENGTH(REPLACE(TRIM(BOTH '<>' FROM Tags), '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 100 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000 
),
QuestionStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Owner,
        t.Tag AS PopularTag
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        TopTags t ON FIND_IN_SET(t.Tag, TRIM(BOTH '<>' FROM p.Tags))
    WHERE 
        p.PostTypeId = 1 
),
FinalReport AS (
    SELECT 
        qs.PostId,
        qs.Title,
        qs.ViewCount,
        qs.CreationDate,
        qs.Owner,
        pu.DisplayName AS PopularOwner,
        pu.Reputation,
        pu.BadgeCount
    FROM 
        QuestionStats qs
    JOIN 
        PopularUsers pu ON qs.Owner = pu.DisplayName
    ORDER BY 
        qs.ViewCount DESC
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.ViewCount,
    FR.CreationDate,
    FR.Owner,
    FR.PopularOwner,
    FR.Reputation,
    FR.BadgeCount
FROM 
    FinalReport FR
WHERE 
    FR.Reputation > 5000 
LIMIT 50;

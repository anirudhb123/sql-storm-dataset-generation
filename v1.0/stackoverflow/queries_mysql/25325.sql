
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),

PostTags AS (
    SELECT 
        rp.PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '>', -1) AS Tag
    FROM 
        RankedPosts rp
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) >= numbers.n - 1
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

TagPopularity AS (
    SELECT 
        pt.Tag,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        pt.Tag
    ORDER BY 
        PostCount DESC
)

SELECT 
    up.DisplayName AS TopUser,
    up.Reputation,
    ub.BadgeCount,
    tp.Tag,
    tp.PostCount,
    tp.AverageScore
FROM 
    Users up
JOIN 
    UserBadges ub ON up.Id = ub.UserId
JOIN 
    PostTags pta ON pta.Tag IN (
        SELECT Tag 
        FROM TagPopularity 
        WHERE PostCount > 5 
        ORDER BY AverageScore DESC 
        LIMIT 3 
    )
JOIN 
    TagPopularity tp ON pta.Tag = tp.Tag
ORDER BY 
    up.Reputation DESC 
LIMIT 10;

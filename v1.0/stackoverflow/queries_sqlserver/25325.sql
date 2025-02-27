
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
        value AS Tag
    FROM 
        RankedPosts rp
    CROSS APPLY STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><') AS TagValue(value)
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
        SELECT TOP 3 Tag 
        FROM TagPopularity 
        WHERE PostCount > 5 
        ORDER BY AverageScore DESC 
    )
JOIN 
    TagPopularity tp ON pta.Tag = tp.Tag
ORDER BY 
    up.Reputation DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;

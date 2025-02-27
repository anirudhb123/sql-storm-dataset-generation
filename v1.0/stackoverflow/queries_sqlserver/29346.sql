
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0)
),
TagUsage AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '>') AS SplitTags
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagUsage
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.AnswerCount,
    tu.TagName,
    tu.TagCount,
    ub.BadgeCount,
    rp.LastActivityDate
FROM 
    RankedPosts rp
JOIN 
    TopTags tu ON rp.Tags LIKE CONCAT('%<', tu.TagName, '>%' ) 
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.ViewRank = 1 
ORDER BY 
    rp.LastActivityDate DESC;

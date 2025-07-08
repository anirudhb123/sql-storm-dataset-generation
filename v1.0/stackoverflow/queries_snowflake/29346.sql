
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
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01'::DATE)
),
TagUsage AS (
    SELECT 
        TRIM(REGEXP_SUBSTR(Tags, '<([^>]+)>', 1, seq.column_value)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => 100)) seq
    WHERE 
        PostTypeId = 1 
        AND REGEXP_COUNT(Tags, '<') > 0
    GROUP BY 
        TRIM(REGEXP_SUBSTR(Tags, '<([^>]+)>', 1, seq.column_value))
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
    TopTags tu ON POSITION(tu.TagName IN rp.Tags) > 0
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.ViewRank = 1 
ORDER BY 
    rp.LastActivityDate DESC;

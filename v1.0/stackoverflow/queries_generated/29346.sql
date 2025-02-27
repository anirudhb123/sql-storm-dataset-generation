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
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TagUsage AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
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
        b.Class = 1 -- Only Gold badges
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
    TopTags tu ON rp.Tags LIKE CONCAT('%<', tu.TagName, '>%' ) -- Tags associated with posts
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.ViewRank = 1 -- Only the most viewed posts per user
ORDER BY 
    rp.LastActivityDate DESC;

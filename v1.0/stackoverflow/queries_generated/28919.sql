WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with a positive score
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS TagsArray
    FROM 
        Posts p
),
TagCounts AS (
    SELECT 
        unnest(TagsArray) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        TagName
),
UserBadges AS (
    SELECT 
        u.Id,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    tc.TagName,
    tc.TagCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts rp
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
JOIN 
    TagCounts tc ON pt.TagsArray @> ARRAY[tc.TagName]
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.Id
WHERE 
    rp.PostRank = 1 -- Get the most recent question per user
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC, 
    tc.TagCount DESC;

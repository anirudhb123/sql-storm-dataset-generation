WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COALESCE(bc.GoldBadges, 0) AS GoldBadges,
        COALESCE(bc.SilverBadges, 0) AS SilverBadges,
        COALESCE(bc.BronzeBadges, 0) AS BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        BadgeCounts bc ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = bc.UserId)
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.ViewCount,
    pwb.OwnerDisplayName,
    pwb.GoldBadges,
    pwb.SilverBadges,
    pwb.BronzeBadges,
    ts.Tag,
    ts.TagCount
FROM 
    PostWithBadges pwb
JOIN 
    TagStatistics ts ON pwb.Title ILIKE '%' || ts.Tag || '%'
WHERE 
    pwb.RankByViews <= 3  -- Getting the top 3 ranked posts by views for each user
ORDER BY 
    pwb.OwnerDisplayName, pwb.ViewCount DESC, ts.TagCount DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
TagAnalysis AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, '> <'))) AS TagName,
        COUNT(*) AS TagCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS ViewedOverHundredCount,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS AnsweredCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        TagName
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
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
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    ta.TagName,
    ta.TagCount,
    ta.ViewedOverHundredCount,
    ta.AnsweredCount,
    ubs.BadgeCount,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    TagAnalysis ta ON ta.TagName = ANY(string_to_array(rp.Tags, '> <'))
LEFT JOIN 
    UserBadgeStats ubs ON rp.OwnerUserId = ubs.UserId
WHERE 
    rp.Rank <= 5 -- Get top 5 most recent questions per user
ORDER BY 
    rp.CreationDate DESC, 
    ta.TagCount DESC;

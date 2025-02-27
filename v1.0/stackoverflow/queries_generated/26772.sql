WITH UserTags AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT t.Id) AS TagCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(Tag) ON t.Tag IS NOT NULL
    WHERE 
        u.Reputation > 5000
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS UsageCount
    FROM 
        Posts
    CROSS JOIN 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS t(Tag)
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC 
    LIMIT 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(p.Id) AS PostCount, 
        AVG(p.ViewCount) AS AvgViews,
        AVG(p.CommentCount) AS AvgComments,
        AVG(p.AnswerCount) AS AvgAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    ut.UserId, 
    ut.DisplayName, 
    ut.TagCount, 
    ut.GoldBadges, 
    ut.SilverBadges, 
    ut.BronzeBadges, 
    COALESCE(ua.PostCount, 0) AS TotalPosts, 
    COALESCE(ua.AvgViews, 0) AS AverageViews, 
    COALESCE(ua.AvgComments, 0) AS AverageComments,
    COALESCE(ua.AvgAnswers, 0) AS AverageAnswers,
    pt.Tag AS PopularTag
FROM 
    UserTags ut
LEFT JOIN 
    UserActivity ua ON ut.UserId = ua.UserId
CROSS JOIN 
    PopularTags pt
WHERE 
    ut.TagCount > 5
ORDER BY 
    ut.TagCount DESC, 
    ut.GoldBadges DESC
LIMIT 50;

WITH TagFrequency AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LEN(Tags) - 2), '> <')))::VARCHAR) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only Questions
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        Frequency,
        RANK() OVER (ORDER BY Frequency DESC) AS Rank
    FROM 
        TagFrequency
    WHERE 
        Frequency > 1  -- Filter tags that are used more than once
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS ActiveRank
    FROM 
        UserActivity
    WHERE 
        PostCount > 0  -- Only users with posts
)
SELECT 
    au.DisplayName,
    au.PostCount,
    au.CommentCount,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    pt.Tag AS PopularTag,
    pt.Frequency AS TagFrequency
FROM 
    ActiveUsers au
JOIN 
    PopularTags pt ON au.ActiveRank <= 10  -- Join top active users
ORDER BY 
    au.PostCount DESC, pt.Frequency DESC;

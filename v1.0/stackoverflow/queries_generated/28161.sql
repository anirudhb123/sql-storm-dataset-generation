WITH TagList AS (
    SELECT 
        Id,
        TRIM(BOTH '>' FROM UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS Tag 
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 -- Only consider questions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id 
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount 
    FROM 
        TagList 
    GROUP BY 
        Tag 
    ORDER BY 
        TagCount DESC 
    LIMIT 10
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerName,
        ub.BadgeCount,
        ub.GoldBadgeCount,
        ub.SilverBadgeCount,
        ub.BronzeBadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
        AND EXISTS (
            SELECT 1 
            FROM TagList t
            WHERE t.Id = p.Id
            INTERSECT
            SELECT Tag 
            FROM PopularTags
        )
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerName,
    ps.BadgeCount,
    ps.GoldBadgeCount,
    ps.SilverBadgeCount,
    ps.BronzeBadgeCount
FROM 
    PostStats ps
ORDER BY 
    ps.ViewCount DESC
LIMIT 20; -- Top 20 questions by view count with popular tags

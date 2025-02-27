WITH TagCount AS (
    SELECT
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagCount
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
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
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        ARRAY_AGG(DISTINCT t.Tag) AS Tags
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT
            p.Id,
            UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
        FROM
            Posts p
        WHERE
            p.PostTypeId = 1
    ) t ON p.Id = t.Id
    WHERE 
        p.ViewCount > 1000
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
)

SELECT
    um.UserId,
    um.DisplayName,
    um.BadgeCount,
    um.GoldBadges,
    um.SilverBadges,
    um.BronzeBadges,
    ARRAY_AGG(DISTINCT t.Tag) AS TopTags,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.CommentCount,
    pm.AnswerCount
FROM
    UserBadges um
JOIN 
    Posts p ON um.UserId = p.OwnerUserId
JOIN 
    PostMetrics pm ON p.Id = pm.PostId
JOIN 
    TopTags t ON t.Tag = ANY(pm.Tags)
WHERE 
    t.TagRank <= 5
GROUP BY 
    um.UserId, um.DisplayName, um.BadgeCount, um.GoldBadges, um.SilverBadges, um.BronzeBadges, pm.Title, pm.CreationDate, pm.Score, pm.CommentCount, pm.AnswerCount
ORDER BY 
    um.BadgeCount DESC, pm.Score DESC;

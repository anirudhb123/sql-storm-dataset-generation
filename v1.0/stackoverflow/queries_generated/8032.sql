WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), TagsStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
), PopularTags AS (
    SELECT 
        TagName
    FROM 
        TagsStats
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    ub.BadgeCount,
    pt.TagName
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = rp.OwnerUserId
JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    Posts p ON p.Id = rp.PostId
JOIN 
    TagsStats ts ON ts.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
JOIN 
    PopularTags pt ON pt.TagName = ts.TagName
WHERE 
    rp.rn = 1 -- Get the latest question for each user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

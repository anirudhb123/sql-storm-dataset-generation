WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= '2023-01-01' -- Questions created in 2023
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 -- Users with high reputation
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    pt.TagName,
    ub.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(rp.Tags, '>'))
WHERE 
    rp.PostRank <= 5 -- Top 5 posts per user
ORDER BY 
    rp.OwnerDisplayName, rp.Score DESC;

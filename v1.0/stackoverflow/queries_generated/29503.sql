WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(Tags, '<>')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount >= 10  -- Tags with at least 10 posts
),
UsersWithBadges AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'  -- Users created within the last year
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    pt.Tag AS PopularTag,
    pt.PostCount AS TagPostCount,
    ub.BadgeCount AS UserBadgeCount
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.Tag || '%'
JOIN 
    UsersWithBadges ub ON rp.OwnerUserId = ub.Id
WHERE 
    rp.RankByUser = 1  -- Only the most recent post per user
ORDER BY 
    pt.PostCount DESC,  -- Order by the popularity of tags
    rp.ViewCount DESC;  -- Then order by post view count

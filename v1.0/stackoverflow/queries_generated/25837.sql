WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(TRIM(BOTH '<>' FROM Tags), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only Questions
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostsWithBadges AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        b.Name AS Badge,
        b.Class AS BadgeClass
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pt.Tag AS PopularTag,
    pwb.Owner,
    pwb.Badge,
    pwb.BadgeClass
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON POSITION(pt.Tag IN rp.Tags) > 0
LEFT JOIN 
    PostsWithBadges pwb ON rp.PostId = pwb.PostId
WHERE 
    rp.Rank = 1  -- Select top-ranked post per owner
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;


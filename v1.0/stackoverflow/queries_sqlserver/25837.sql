
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
        p.PostTypeId = 1  
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),
PopularTags AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(TRIM(REPLACE(REPLACE(Tags, '<', ''), '>', '')), '><') 
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
        p.PostTypeId = 1  
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
    PopularTags pt ON CHARINDEX(pt.Tag, rp.Tags) > 0
LEFT JOIN 
    PostsWithBadges pwb ON rp.PostId = pwb.PostId
WHERE 
    rp.Rank = 1  
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;

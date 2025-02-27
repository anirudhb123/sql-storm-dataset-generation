
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
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH '<>' FROM Tags), '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts 
    JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers, (SELECT @row := 0) r) n
    WHERE 
        PostTypeId = 1
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
    PopularTags pt ON FIND_IN_SET(pt.Tag, REPLACE(REPLACE(rp.Tags, '<', '>'), '>', '')) > 0
LEFT JOIN 
    PostsWithBadges pwb ON rp.PostId = pwb.PostId
WHERE 
    rp.Rank = 1  
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;

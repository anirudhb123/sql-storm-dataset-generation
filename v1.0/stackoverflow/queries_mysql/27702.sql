
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.Score > 0  
),
TagOccurrence AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
),
PopularTags AS (
    SELECT 
        Tag,
        TagCount
    FROM 
        TagOccurrence
    WHERE 
        TagCount > 10  
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT pt.Name) AS PostTypes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        PostTypes pt ON pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = rp.PostId)
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    COALESCE(pt.TagCount, 0) AS PopularTagCount,
    ps.PostTypes
FROM 
    PostStats ps
LEFT JOIN 
    PopularTags pt ON ps.Title LIKE CONCAT('%', pt.Tag, '%')  
WHERE 
    ps.CommentCount > 5  
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;

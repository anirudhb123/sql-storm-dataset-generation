
WITH RecentPosts AS (
    SELECT 
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 30 DAY
),
TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '>', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RecentPosts
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= n.n - 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 1 
),
PopularPosts AS (
    SELECT 
        rp.*,
        tt.Tag,
        tt.TagCount
    FROM 
        RecentPosts rp
    JOIN 
        TopTags tt ON rp.Tags LIKE CONCAT('%', tt.Tag, '%')
    ORDER BY 
        rp.ViewCount DESC, 
        rp.Score DESC
    LIMIT 10
)
SELECT 
    pp.Title,
    pp.OwnerDisplayName,
    pp.ViewCount,
    pp.Score,
    pp.CreationDate,
    pp.Tag,
    pp.TagCount
FROM 
    PopularPosts pp
ORDER BY 
    pp.CreationDate DESC;

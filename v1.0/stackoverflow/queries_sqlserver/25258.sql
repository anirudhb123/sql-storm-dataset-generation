
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
        AND p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
),
TagCounts AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RecentPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '>') 
    GROUP BY 
        value
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
        TopTags tt ON rp.Tags LIKE '%' + tt.Tag + '%'
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
    pp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

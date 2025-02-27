
WITH PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        LEN(REPLACE(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><', ','), '>', '')) - LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><', '')) + 1 AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        p.ViewCount,
        p.CommentCount,
        p.FavoriteCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM 
        Posts p
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagUsage
    FROM 
        PostWithTags
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags)-2), '><')
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        Tag,
        TagUsage
    FROM 
        PopularTags
    ORDER BY 
        TagUsage DESC
    OFFSET 0 ROWS
    FETCH NEXT 10 ROWS ONLY
),
PostsWithTopTags AS (
    SELECT 
        pwt.PostId,
        pwt.Title,
        pwt.CreationDate,
        pwt.Score,
        pwt.TagCount,
        pwt.OwnerDisplayName,
        pwt.AnswerCount,
        pwt.ViewCount,
        pwt.CommentCount,
        pwt.FavoriteCount,
        pwt.PostType,
        tt.Tag
    FROM 
        PostWithTags pwt
    JOIN 
        TopTags tt ON tt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(pwt.Tags, 2, LEN(pwt.Tags)-2), '><'))
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.TagCount,
    p.OwnerDisplayName,
    p.AnswerCount,
    p.ViewCount,
    p.CommentCount,
    p.FavoriteCount,
    p.PostType,
    COUNT(DISTINCT p.Tag) as UsedTagCount
FROM 
    PostsWithTopTags p
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Score, p.TagCount, p.OwnerDisplayName, p.AnswerCount, p.ViewCount, p.CommentCount, p.FavoriteCount, p.PostType
ORDER BY 
    UsedTagCount DESC, p.Score DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;

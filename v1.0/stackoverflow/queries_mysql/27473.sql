
WITH PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        LENGTH(REPLACE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><', ',')) - LENGTH(REPLACE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), ',', '')) + 1 AS TagCount,
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
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS TagUsage
    FROM 
        PostWithTags
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(SUBSTRING(Tags, 2, LENGTH(Tags)-2)) - CHAR_LENGTH(REPLACE(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><', '')) >= n.n - 1
    GROUP BY Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagUsage
    FROM 
        PopularTags
    ORDER BY 
        TagUsage DESC
    LIMIT 10
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
        TopTags tt ON FIND_IN_SET(tt.Tag, REPLACE(SUBSTRING(pwt.Tags, 2, LENGTH(pwt.Tags)-2), '><', ',')) > 0
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
LIMIT 100;

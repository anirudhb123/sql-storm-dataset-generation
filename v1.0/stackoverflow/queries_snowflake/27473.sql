
WITH PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        ARRAY_SIZE(SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS TagCount,
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
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        VALUE AS Tag,
        COUNT(*) AS TagUsage
    FROM 
        PostWithTags,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(Tags, 2, LENGTH(Tags)-2), '><'))
    GROUP BY 
        Tag
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
        TopTags tt ON tt.Tag IN (SELECT VALUE FROM LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(pwt.Tags, 2, LENGTH(pwt.Tags)-2), '><')))
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
    COUNT(DISTINCT p.Tag) AS UsedTagCount
FROM 
    PostsWithTopTags p
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Score, p.TagCount, p.OwnerDisplayName, p.AnswerCount, p.ViewCount, p.CommentCount, p.FavoriteCount, p.PostType
ORDER BY 
    UsedTagCount DESC, p.Score DESC
LIMIT 100;

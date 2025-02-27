
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        @rownum := IF(@prev_type = p.PostTypeId, @rownum + 1, 1) AS Rank,
        @prev_type := p.PostTypeId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        TIMESTAMPDIFF(SECOND, p.CreationDate, '2024-10-01 12:34:56') AS AgeInSeconds
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId,
        (SELECT @rownum := 0, @prev_type := NULL) r
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
    AND 
        (p.Body LIKE '%performance%' OR p.Title LIKE '%performance%')
),
PostTagCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        @tag_rank := @tag_rank + 1 AS TagRank
    FROM 
        PostTagCounts, (SELECT @tag_rank := 0) r
    ORDER BY 
        TagCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.AgeInSeconds,
    tt.Tag AS TopTag
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON tt.TagRank <= 5
WHERE 
    rp.Rank <= 10
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Score, rp.ViewCount, rp.AgeInSeconds, tt.Tag
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;

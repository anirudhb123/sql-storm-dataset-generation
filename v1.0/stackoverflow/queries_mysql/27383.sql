
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Tags IS NOT NULL
),
TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH '<>' FROM Tags), '> <', numbers.n), '> <', -1) AS Tag,
        PostId
    FROM 
        TaggedPosts 
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(TRIM(BOTH '<>' FROM Tags)) - CHAR_LENGTH(REPLACE(TRIM(BOTH '<>' FROM Tags), '> <', '')) >= numbers.n - 1
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        AVG(AnswerCount) AS AvgAnswerCount
    FROM 
        TagCounts tc
    JOIN 
        TaggedPosts tp ON tc.PostId = tp.PostId
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        AvgViewCount,
        AvgAnswerCount,
        @rank := IF(@prevPostCount = PostCount, @rank, @rank + 1) AS TagRank,
        @prevPostCount := PostCount
    FROM 
        TagStatistics, (SELECT @rank := 0, @prevPostCount := NULL) r
    ORDER BY 
        PostCount DESC
)
SELECT 
    t.Tag,
    t.PostCount,
    t.AvgViewCount,
    t.AvgAnswerCount
FROM 
    PopularTags t
WHERE 
    t.TagRank <= 10  
ORDER BY 
    t.PostCount DESC;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 
         UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
         UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
         UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.Tags IS NOT NULL
),
TagStats AS (
    SELECT 
        ft.Tag,
        COUNT(*) AS TagCount,
        SUM(CASE WHEN rp.ScoreRank = 1 THEN 1 ELSE 0 END) AS TopScoreQuestions
    FROM 
        FilteredTags ft
    JOIN 
        RankedPosts rp ON ft.PostId = rp.PostId
    GROUP BY 
        ft.Tag, rp.ScoreRank
), 
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        TopScoreQuestions,
        ROW_NUMBER() OVER (ORDER BY TopScoreQuestions DESC, TagCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    tt.Tag,
    tt.TagCount,
    tt.TopScoreQuestions,
    CONCAT('Tag ', tt.Tag, ' was used in ', tt.TagCount, ' questions and had ', tt.TopScoreQuestions, ' top scoring questions.') AS BenchmarkSummary
FROM 
    TopTags tt
WHERE 
    tt.TagRank <= 10
ORDER BY 
    tt.TagCount DESC;


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
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><') 
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
        ft.Tag
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
    'Tag ' + tt.Tag + ' was used in ' + CAST(tt.TagCount AS VARCHAR) + ' questions and had ' + CAST(tt.TopScoreQuestions AS VARCHAR) + ' top scoring questions.' AS BenchmarkSummary
FROM 
    TopTags tt
WHERE 
    tt.TagRank <= 10
ORDER BY 
    tt.TagCount DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Last year
),
TagAnalysis AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AverageViewCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        Tag
)
SELECT 
    ra.OwnerDisplayName,
    ra.Title,
    ra.PostId,
    ra.CreationDate,
    ra.ViewCount,
    ra.Score,
    ta.Tag,
    ta.PostCount,
    ta.AverageViewCount,
    ta.AverageScore
FROM 
    RankedPosts ra
JOIN 
    TagAnalysis ta ON ra.Tags LIKE '%' || ta.Tag || '%'
WHERE 
    ra.TagRank <= 3 -- Top 3 ranked posts per tag
ORDER BY 
    ta.PostCount DESC, 
    ra.ViewCount DESC;
This query benchmarks string processing by analyzing post titles and tags within the past year. It ranks posts per tag by view count, calculates average metrics, and displays the top three posts for each tag based on their performance.

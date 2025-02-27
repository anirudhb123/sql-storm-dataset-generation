WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(NULLIF(ps.Score, 0), 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, SUM(Score) AS Score FROM Votes GROUP BY PostId) ps ON p.Id = ps.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
      AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
AggregatedTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag
    FROM 
        RankedPosts
    WHERE 
        Tag IS NOT NULL
),
TagMetrics AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        RankedPosts r
    JOIN 
        AggregatedTags a ON r.Tags LIKE '%' || a.Tag || '%'
    GROUP BY 
        Tag
)
SELECT 
    tm.Tag,
    tm.PostCount,
    tm.TotalViews,
    tm.AverageScore,
    CASE 
        WHEN tm.AverageScore >= 10 THEN 'High'
        WHEN tm.AverageScore BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS QualityCategory
FROM 
    TagMetrics tm
ORDER BY 
    tm.TotalViews DESC, 
    tm.PostCount DESC;

This SQL query benchmarks string processing by extracting and analyzing data related to posts in the defined schema. It ranks questions based on view counts, aggregates tag metrics, and categorizes the quality of tags based on the average score of associated questions.

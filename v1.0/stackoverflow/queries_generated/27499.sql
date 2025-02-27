WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with a score
),

TagStatistics AS (
    SELECT 
        TRIM(SUBSTRING(tag, 2, LENGTH(tag) - 2)) AS Tag,
        COUNT(*) AS QuestionCount,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        RankedPosts rp,
        UNNEST(string_to_array(rp.Tags, '>')) AS tag
    WHERE 
        rp.TagRank <= 5 -- Top 5 posts per tag
    GROUP BY 
        Tag
),

PopularTags AS (
    SELECT 
        Tag, 
        QuestionCount,
        (AvgScore * QuestionCount) AS WeightedScore,
        TotalViews
    FROM 
        TagStatistics
    ORDER BY 
        WeightedScore DESC
    LIMIT 10
)

SELECT 
    pt.Tag,
    pt.QuestionCount,
    pt.WeightedScore,
    pt.TotalViews,
    (SELECT string_agg(DISTINCT rp.Title, ', ') 
     FROM RankedPosts rp 
     WHERE rp.Tags LIKE '%' || pt.Tag || '%') AS TopQuestionsTitles
FROM 
    PopularTags pt;

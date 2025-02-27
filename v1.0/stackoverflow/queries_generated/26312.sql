WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Title ORDER BY p.CreationDate DESC) AS TitleRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.Title IS NOT NULL
),
TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.TotalAnswers,
        RANK() OVER (ORDER BY ts.TotalViews DESC) AS TagRank
    FROM 
        TagStatistics ts
    WHERE
        ts.PostCount > 0
),
PopularPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        rp.OwnerDisplayName,
        tt.TagName,
        tt.TagRank
    FROM 
        RankedPosts rp
    JOIN 
        TopTags tt ON rp.Title LIKE '%' || tt.TagName || '%'
    WHERE 
        rp.TitleRank = 1  -- Latest post with a unique title
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.AnswerCount,
    pp.Score,
    pp.OwnerDisplayName,
    pp.TagName,
    pp.TagRank
FROM 
    PopularPosts pp
ORDER BY 
    pp.ViewCount DESC,
    pp.AnswerCount DESC
LIMIT 10;

This SQL query retrieves the top 10 most viewed and answered questions along with the most popular tags from the Stack Overflow schema. It first ranks posts by title and counts statistics for tags, then combines the results to get the most popular posts while ensuring each selected post is the latest for that title.

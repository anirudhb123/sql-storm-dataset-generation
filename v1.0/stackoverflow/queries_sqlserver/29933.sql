
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.Tags,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 
),
TagStatistics AS (
    SELECT
        TRIM(BOTH '<>' FROM tag) AS Tag,
        COUNT(*) AS TotalQuestions,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM (
        SELECT 
            value AS tag,
            ViewCount,
            Score
        FROM 
            RankedPosts
        CROSS APPLY STRING_SPLIT(TRIM(BOTH '<>' FROM Tags), '>tag<')
    ) AS unnested_tags
    GROUP BY 
        TRIM(BOTH '<>' FROM tag)
),
TopAuthorStats AS (
    SELECT 
        Author,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        RankedPosts
    GROUP BY 
        Author
)
SELECT 
    ts.Tag,
    ts.TotalQuestions,
    ts.TotalViews,
    ts.AverageScore,
    tas.Author,
    tas.TotalPosts,
    tas.TotalViews AS AuthorViews,
    tas.AverageScore AS AuthorAverageScore
FROM 
    TagStatistics ts
JOIN 
    TopAuthorStats tas ON ts.TotalQuestions > 5 
ORDER BY 
    ts.TotalQuestions DESC,
    tas.TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

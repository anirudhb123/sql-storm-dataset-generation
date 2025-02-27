
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
            SUBSTRING_INDEX(SUBSTRING_INDEX(Trim(Both '<>' FROM Tags), '>tag<', n.n), '>tag<', -1) AS tag,
            ViewCount,
            Score
        FROM 
            RankedPosts
        JOIN 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
            ON CHAR_LENGTH(Trim(Both '<>' FROM Tags) ) - CHAR_LENGTH(REPLACE(Trim(Both '<>' FROM Tags), '>tag<', '')) >= n.n - 1
    ) AS unnested_tags
    GROUP BY 
        Tag
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
LIMIT 10;

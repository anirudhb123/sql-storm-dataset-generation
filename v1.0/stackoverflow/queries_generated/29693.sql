WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Owner,
        DENSE_RANK() OVER (PARTITION BY SUBSTRING(p.Tags FROM '>(.*?)<') ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Questions from the last year
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        ViewCount,
        Score,
        Owner,
        TagRank
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5  -- Top 5 questions per tag
)
SELECT 
    tq.Tags,
    COUNT(tq.PostId) AS TotalQuestions,
    AVG(tq.ViewCount) AS AverageViews,
    SUM(tq.Score) AS TotalScore,
    STRING_AGG(tq.Title, '; ') AS QuestionTitles
FROM 
    TopQuestions tq
GROUP BY 
    tq.Tags
ORDER BY 
    TotalQuestions DESC, AverageViews DESC;


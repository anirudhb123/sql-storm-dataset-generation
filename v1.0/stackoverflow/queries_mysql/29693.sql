
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Owner,
        DENSE_RANK() OVER (PARTITION BY SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', -1), '<', 1) ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR  
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
        TagRank <= 5  
)
SELECT 
    tq.Tags,
    COUNT(tq.PostId) AS TotalQuestions,
    AVG(tq.ViewCount) AS AverageViews,
    SUM(tq.Score) AS TotalScore,
    GROUP_CONCAT(tq.Title SEPARATOR '; ') AS QuestionTitles
FROM 
    TopQuestions tq
GROUP BY 
    tq.Tags
ORDER BY 
    TotalQuestions DESC, AverageViews DESC;

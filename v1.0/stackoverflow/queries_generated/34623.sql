WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
PostMetrics AS (
    SELECT 
        pu.Id AS UserId,
        pu.DisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalQuestions,
        SUM(rp.AnswerCount) AS TotalAnswers,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AverageScore
    FROM 
        Users pu
    LEFT JOIN 
        RankedPosts rp ON pu.Id = rp.OwnerUserId
    GROUP BY 
        pu.Id, pu.DisplayName
),
FeaturedTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.TagName) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.TagName) > 5
    ORDER BY 
        TagCount DESC
)
SELECT 
    pm.UserId,
    pm.DisplayName,
    pm.TotalQuestions,
    pm.TotalAnswers,
    pm.TotalViews,
    pm.AverageScore,
    ft.TagName,
    ft.TagCount
FROM 
    PostMetrics pm
LEFT JOIN 
    FeaturedTags ft ON pm.TotalViews > 1000
WHERE 
    pm.TotalQuestions > 10
ORDER BY 
    pm.TotalAnswers DESC, pm.TotalViews DESC;

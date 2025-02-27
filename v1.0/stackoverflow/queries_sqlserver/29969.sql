
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ISNULL(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING(value, 2, LEN(value) - 2)) AS TagName
    FROM 
        RankedPosts
    CROSS APPLY 
        STRING_SPLIT(Tags, '>') AS value
    GROUP BY 
        TRIM(SUBSTRING(value, 2, LEN(value) - 2))
),
PostsWithMostAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(a.Id) AS TotalAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    pt.TagName,
    COUNT(DISTINCT rp.PostId) AS QuestionCount,
    ISNULL(SUM(pma.TotalAnswers), 0) AS TotalAnswers,
    AVG(rp.ViewCount) AS AvgViewCount,
    AVG(DATEDIFF(MINUTE, rp.CreationDate, GETDATE())) AS AvgTimeSinceCreation
FROM 
    PopularTags pt
JOIN 
    RankedPosts rp ON rp.Tags LIKE '%' + pt.TagName + '%' 
LEFT JOIN 
    PostsWithMostAnswers pma ON rp.PostId = pma.PostId
WHERE 
    rp.TagRank <= 5 
GROUP BY 
    pt.TagName
ORDER BY 
    QuestionCount DESC, TotalAnswers DESC;

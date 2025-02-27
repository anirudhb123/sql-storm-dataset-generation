
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.AnswerCount DESC) AS RankByAnswers
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01')
),
TagUsage AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(TRIM(BOTH '<>' FROM Tags), '><')
    GROUP BY 
        value
)
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.AnswerCount) AS TotalAnswers,
    STRING_AGG(DISTINCT tu.TagName, ', ') AS UsedTags
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    TagUsage tu ON tu.TagName IN (SELECT value FROM STRING_SPLIT(TRIM(BOTH '<>' FROM p.Tags), '><'))
WHERE 
    p.CreationDate >= DATEADD(year, -1, '2024-10-01')
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5 
ORDER BY 
    TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;


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
        TRIM(BOTH '<>' FROM t.TagName) AS TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            TRIM(BOTH '<>' FROM Tags) AS Tags
        FROM 
            RankedPosts
    ) AS r, 
    LATERAL FLATTEN(input => SPLIT(Tags, '><')) AS t
    GROUP BY 
        TagName
)
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.AnswerCount) AS TotalAnswers,
    LISTAGG(DISTINCT tu.TagName, ', ') AS UsedTags
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    TagUsage tu ON tu.TagName IN (SELECT TRIM(BOTH '<>' FROM value) FROM TABLE(FLATTEN(input => SPLIT(TRIM(BOTH '<>' FROM p.Tags), '><'))))
WHERE 
    p.CreationDate >= DATEADD(year, -1, '2024-10-01')
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5 
ORDER BY 
    TotalViews DESC
LIMIT 10;

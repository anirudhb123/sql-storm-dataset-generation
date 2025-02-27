
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
        AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH '<>' FROM Tags), '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts 
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    WHERE 
        CHAR_LENGTH(TRIM(BOTH '<>' FROM Tags)) - CHAR_LENGTH(REPLACE(TRIM(BOTH '<>' FROM Tags), '><', '')) >= n.n - 1
    GROUP BY 
        TagName
)
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.AnswerCount) AS TotalAnswers,
    GROUP_CONCAT(DISTINCT tu.TagName ORDER BY tu.TagName ASC) AS UsedTags
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    TagUsage tu ON FIND_IN_SET(tu.TagName, TRIM(BOTH '<>' FROM p.Tags)) > 0
WHERE 
    p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5 
ORDER BY 
    TotalViews DESC
LIMIT 10;

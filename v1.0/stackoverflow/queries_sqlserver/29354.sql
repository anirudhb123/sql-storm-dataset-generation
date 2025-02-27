
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),

RankedTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
)

SELECT 
    rt.TagName,
    rt.PostCount,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    AVG(ISNULL(c.Score, 0)) AS AverageCommentScore,
    MAX(p.ViewCount) AS MaxViewCount,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    RankedTags rt
JOIN 
    Posts p ON p.Tags LIKE '%' + rt.TagName + '%'
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON b.UserId = u.Id
WHERE 
    rt.Rank <= 10 
GROUP BY 
    rt.TagName, rt.PostCount
ORDER BY 
    rt.PostCount DESC;


WITH TagCounts AS (
    SELECT 
        SPLIT(TRIM(BOTH '<>' FROM Tags), '><') AS TagArray,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tags
),

RankedTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        (SELECT Tag, PostCount FROM TagCounts CROSS JOIN LATERAL FLATTEN(input => TagArray) AS TagName)
)

SELECT 
    rt.TagName,
    rt.PostCount,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    AVG(COALESCE(c.Score, 0)) AS AverageCommentScore,
    MAX(p.ViewCount) AS MaxViewCount,
    LISTAGG(DISTINCT u.DisplayName, ', ') WITHIN GROUP (ORDER BY u.DisplayName) AS ActiveUsers,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    RankedTags rt
JOIN 
    Posts p ON p.Tags LIKE '%' || rt.TagName || '%'
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

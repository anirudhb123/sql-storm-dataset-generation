
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
        UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 
        UNION SELECT 9 UNION SELECT 10 
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
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
    AVG(IFNULL(c.Score, 0)) AS AverageCommentScore,
    MAX(p.ViewCount) AS MaxViewCount,
    GROUP_CONCAT(DISTINCT u.DisplayName SEPARATOR ', ') AS ActiveUsers,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    RankedTags rt
JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', rt.TagName, '%')
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

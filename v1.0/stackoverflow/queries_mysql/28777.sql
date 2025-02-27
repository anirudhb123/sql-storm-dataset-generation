
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        AVG(TIMESTAMPDIFF(SECOND, p.CreationDate, '2024-10-01 12:34:56') / 3600) AS AvgPostAgeHours
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(*) AS UsageCount
    FROM 
        PopularTags pt
    JOIN 
        Tags t ON t.TagName = pt.TagName
    GROUP BY 
        t.TagName
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.TotalScore,
    ups.AvgPostAgeHours,
    tu.TagName,
    tu.UsageCount
FROM 
    UserPostStats ups
JOIN 
    TagUsage tu ON tu.UsageCount = (
        SELECT 
            MAX(UsageCount) 
        FROM 
            TagUsage 
    )
ORDER BY 
    ups.TotalPosts DESC, 
    ups.TotalScore DESC;


WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        AVG(DATEDIFF('hour', p.CreationDate, '2024-10-01 12:34:56')) AS AvgPostAgeHours
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
        TRIM(value) AS TagName
    FROM 
        Posts p,
        LATERAL FLATTEN(input => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS value
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

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        MAX(u.Reputation) AS UserReputation,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagUsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AcceptedAnswers,
    ups.AvgScore,
    ups.AvgViews,
    ups.UserReputation,
    COUNT(DISTINCT pt.TagName) AS UniqueTagsUsed,
    ARRAY_AGG(pt.TagName ORDER BY pt.TagUsageCount DESC) AS TopTags
FROM 
    UserPostStats ups
JOIN 
    Posts p ON ups.UserId = p.OwnerUserId
JOIN 
    PopularTags pt ON p.Tags LIKE CONCAT('%', pt.TagName, '%')
GROUP BY 
    ups.UserId
ORDER BY 
    ups.TotalPosts DESC
LIMIT 10;

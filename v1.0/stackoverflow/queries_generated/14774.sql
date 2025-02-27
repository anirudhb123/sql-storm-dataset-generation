-- Performance benchmarking query for StackOverflow schema
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= '2020-01-01'  -- Users created in 2020 or later
    GROUP BY 
        u.Id, u.Reputation
),
TagPostStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    GROUP BY 
        t.TagName
)
SELECT 
    ups.UserId,
    ups.Reputation,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.TotalScore,
    ups.TotalViews,
    ups.AverageScore,
    ups.AverageViews,
    tps.TagName,
    tps.TotalPosts AS TagTotalPosts,
    tps.TotalViews AS TagTotalViews,
    tps.AverageScore AS TagAverageScore
FROM 
    UserPostStats ups
LEFT JOIN 
    TagPostStats tps ON ups.TotalPosts > 0
ORDER BY 
    ups.TotalPosts DESC, ups.Reputation DESC;

-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TaggedPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT t.Id) AS TotalTags,
        COUNT(DISTINCT p.Id) AS PostsWithTags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalViews,
    ups.TotalScore,
    COALESCE(tps.TotalTags, 0) AS TotalTags,
    COALESCE(tps.PostsWithTags, 0) AS PostsWithTags
FROM 
    UserPostStats ups
LEFT JOIN 
    TaggedPostStats tps ON ups.UserId = tps.OwnerUserId
ORDER BY 
    ups.TotalScore DESC, 
    ups.TotalPosts DESC;

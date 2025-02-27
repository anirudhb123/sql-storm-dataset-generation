WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        (SELECT COUNT(c.Id)
         FROM Comments c
         WHERE c.UserId = u.Id) AS TotalComments,
        AVG(v.CreationDate) AS AverageVoteTime
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
        LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalComments,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AverageScore
FROM 
    UserActivity ua
    LEFT JOIN TagStatistics ts ON ua.TotalPosts > 0
WHERE 
    ua.TotalPosts > (SELECT AVG(TotalPosts) FROM UserActivity) OR 
    ts.TotalViews > 1000
ORDER BY 
    ua.TotalPosts DESC, 
    ts.TotalViews DESC
LIMIT 10;

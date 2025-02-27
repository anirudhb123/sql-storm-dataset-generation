
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName SEPARATOR ', ') AS TopContributors
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
),
RecentActivity AS (
    SELECT 
        p.Title,
        p.CreationDate,
        GROUP_CONCAT(DISTINCT c.Text ORDER BY c.Text SEPARATOR ' | ') AS RecentComments,
        GROUP_CONCAT(DISTINCT CONCAT(u.DisplayName, ' (', c.CreationDate, ')') ORDER BY u.DisplayName SEPARATOR ', ') AS UsersCommented
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = c.UserId
    WHERE 
        p.LastActivityDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    ts.TagName,
    ts.TotalPosts,
    ts.TotalQuestions,
    ts.TotalAnswers,
    ts.TotalViews,
    ts.AverageScore,
    ts.TopContributors,
    ra.Title AS RecentPostTitle,
    ra.CreationDate AS RecentPostDate,
    ra.RecentComments,
    ra.UsersCommented
FROM 
    TagStats ts
LEFT JOIN 
    RecentActivity ra ON FIND_IN_SET(ts.TagName, (SELECT GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ',') FROM Tags t))
ORDER BY 
    ts.TotalQuestions DESC, ts.TotalPosts DESC
LIMIT 10;

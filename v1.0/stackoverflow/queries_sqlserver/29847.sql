
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + CAST('<' + t.TagName + '>' AS NVARCHAR(MAX)) + '%'
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
),
RecentActivity AS (
    SELECT 
        p.Title,
        p.CreationDate,
        STRING_AGG(DISTINCT c.Text, ' | ') AS RecentComments,
        STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (', CONVERT(VARCHAR, c.CreationDate, 120), ')'), ', ') AS UsersCommented
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = c.UserId
    WHERE 
        p.LastActivityDate > DATEADD(DAY, -30, CAST('2024-10-01 12:34:56' AS DATETIME))
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
    RecentActivity ra ON CHARINDEX(ts.TagName, (SELECT STRING_AGG(DISTINCT t.TagName, ',') FROM Tags t)) > 0
ORDER BY 
    ts.TotalQuestions DESC, ts.TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

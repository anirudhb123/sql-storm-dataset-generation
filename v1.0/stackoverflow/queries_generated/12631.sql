WITH PostCounts AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT p.OwnerUserId) AS TotalUsers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(u.Views) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.OwnerUserId) AS TotalUsers
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
)

SELECT 
    'PostCounts' AS MetricType,
    PostTypeId,
    TotalPosts,
    TotalUsers,
    TotalScore,
    TotalViews
FROM PostCounts

UNION ALL

SELECT 
    'UserStats' AS MetricType,
    UserId,
    TotalPosts,
    TotalScore,
    TotalUpVotes,
    TotalDownVotes
FROM UserStats

UNION ALL

SELECT 
    'TagStats' AS MetricType,
    TagName,
    TotalPosts,
    TotalViews,
    TotalScore,
    TotalUsers
FROM TagStats
ORDER BY MetricType, PostTypeId;

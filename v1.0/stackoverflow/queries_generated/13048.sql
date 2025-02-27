-- Performance Benchmarking Query: Analyzing Post and User Statistics

WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(CASE WHEN p.CreationDate IS NOT NULL THEN DATEDIFF(second, p.CreationDate, GETDATE()) END) AS AvgPostAgeInSeconds
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

UserStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(DATEDIFF(second, u.CreationDate, GETDATE())) AS AvgAccountAgeInSeconds
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.TotalViews,
    ps.TotalScore,
    ps.AvgPostAgeInSeconds,
    us.DisplayName AS UserName,
    us.TotalBadges,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.AvgAccountAgeInSeconds
FROM 
    PostStatistics ps
JOIN 
    UserStatistics us ON ps.TotalPosts > 0
ORDER BY 
    ps.TotalPosts DESC, us.TotalBadges DESC;

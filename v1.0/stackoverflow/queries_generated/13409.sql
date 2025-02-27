-- Performance benchmarking query for StackOverflow schema

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG((EXTRACT(EPOCH FROM u.LastAccessDate) - EXTRACT(EPOCH FROM u.CreationDate)) / 60) AS AvgMinutesActive
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(EXTRACT(EPOCH FROM p.LastActivityDate - p.CreationDate) / 60) AS AvgMinutesToActivity
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.BadgeCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.AvgMinutesActive,
    COALESCE(p.PostCount, 0) AS PostCount,
    COALESCE(p.TotalViews, 0) AS TotalViews,
    COALESCE(p.TotalScore, 0) AS TotalScore,
    COALESCE(p.AvgMinutesToActivity, 0) AS AvgMinutesToActivity
FROM 
    UserStats u
LEFT JOIN 
    PostStats p ON u.UserId = p.OwnerUserId
ORDER BY 
    u.BadgeCount DESC, u.TotalScore DESC;

-- Performance Benchmarking Query

WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.CreationDate) AS AvgCreationDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        b.Class AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
)

SELECT 
    us.UserId,
    us.Reputation,
    us.UpVotes,
    us.DownVotes,
    ps.PostCount,
    ps.TotalScore,
    ps.TotalViews,
    ps.AvgCreationDate,
    MAX(us.BadgeClass) AS HighestBadgeClass
FROM 
    UserStats us
LEFT JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId
GROUP BY 
    us.UserId, us.Reputation, us.UpVotes, us.DownVotes, ps.PostCount, ps.TotalScore, ps.TotalViews, ps.AvgCreationDate
ORDER BY 
    ps.TotalViews DESC
LIMIT 10;

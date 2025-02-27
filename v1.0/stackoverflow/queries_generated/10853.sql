-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS PostCount,
        COUNT(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswerCount,
        AVG(v.Score) AS AverageScore,
        SUM(CASE WHEN p.CreationDate >= NOW() - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPostsCount
    FROM 
        Posts p 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    pt.Name AS PostType,
    ps.PostCount,
    ps.AcceptedAnswerCount,
    ps.AverageScore,
    ps.RecentPostsCount,
    us.UserId,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.AverageReputation
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
JOIN 
    UserStats us ON us.UserId IS NOT NULL -- Adjust based on criteria to include specific users
ORDER BY 
    ps.PostCount DESC;

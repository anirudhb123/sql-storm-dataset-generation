-- Performance Benchmark Query
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        pht.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory pht
    GROUP BY 
        pht.PostHistoryTypeId
)

SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.AverageScore,
    ps.TotalViews,
    ps.TotalAnswers,
    us.TotalBadges,
    us.TotalUpVotes,
    us.TotalDownVotes,
    pht.Name AS PostHistoryType,
    phs.HistoryCount
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
JOIN 
    UserStats us ON us.TotalBadges > 0 -- Example filtering condition for users with badges
JOIN 
    PostHistoryStats phs ON phs.HistoryCount > 0 -- Example filtering condition for post history
JOIN 
    PostHistoryTypes pht ON phs.PostHistoryTypeId = pht.Id
ORDER BY 
    ps.TotalPosts DESC, us.TotalUpVotes DESC;

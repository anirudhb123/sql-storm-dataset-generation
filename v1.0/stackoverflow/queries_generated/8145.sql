WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id
),
RecentActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalAnswers,
        ua.TotalQuestions,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        DATE_PART('day', NOW() - ua.LastPostDate) AS DaysSinceLastPost
    FROM 
        UserActivity ua
    WHERE 
        ua.LastPostDate >= NOW() - INTERVAL '30 days'
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Date >= NOW() - INTERVAL '365 days'
    GROUP BY 
        UserId
)
SELECT 
    r.UserId,
    r.DisplayName,
    r.TotalPosts,
    r.TotalAnswers,
    r.TotalQuestions,
    r.TotalUpVotes,
    r.TotalDownVotes,
    r.DaysSinceLastPost,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    RecentActivity r
LEFT JOIN 
    BadgeCounts b ON r.UserId = b.UserId
ORDER BY 
    r.TotalPosts DESC, 
    r.TotalUpVotes DESC
LIMIT 10;

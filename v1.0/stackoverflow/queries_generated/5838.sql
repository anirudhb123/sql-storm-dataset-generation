WITH UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT ph.Id) AS TotalPostHistoryActions,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUserPostStats AS (
    SELECT 
        u.UserId,
        COUNT(CASE WHEN p.CreatedDate >= NOW() - INTERVAL '30 days' THEN 1 END) AS RecentPosts,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionsAsked,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS AnswersGiven
    FROM 
        UserScoreSummary u
    JOIN 
        Posts p ON u.UserId = p.OwnerUserId
    GROUP BY 
        u.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalPosts,
    us.TotalComments,
    us.TotalBadges,
    us.TotalPostHistoryActions,
    a.RecentPosts,
    a.QuestionsAsked,
    a.AnswersGiven,
    EXTRACT(YEAR FROM AGE(NOW(), us.AccountCreationDate)) AS AccountAgeYears
FROM 
    UserScoreSummary us
JOIN 
    ActiveUserPostStats a ON us.UserId = a.UserId
WHERE 
    us.TotalUpVotes > 100
ORDER BY 
    us.TotalUpVotes DESC,
    us.TotalPosts DESC
LIMIT 100;

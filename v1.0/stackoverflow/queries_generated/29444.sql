WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 50  -- Filter for users with a certain reputation
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        p.Id AS PostId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentChange
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'  -- Posts with recent changes
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalViews,
    ua.TotalBadges,
    COUNT(DISTINCT rph.PostId) AS RecentChanges,
    COUNT(CASE WHEN rph.RecentChange = 1 THEN 1 END) AS LatestPostChange,
    ARRAY_AGG(DISTINCT rph.Title ORDER BY rph.CreationDate DESC) AS RecentPostTitles
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPostHistory rph ON ua.UserId = rph.UserId
GROUP BY 
    ua.UserId
ORDER BY 
    ua.Reputation DESC
LIMIT 10;  -- Limiting to top 10 users based on reputation

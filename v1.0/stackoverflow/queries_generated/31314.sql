WITH RECURSIVE PostHierarchy AS (
    SELECT
        Id AS PostId,
        Title,
        ParentId,
        CreationDate,
        Score,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        p.Score,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.OwnerUserId,
        p.LastActivityDate,
        row_number() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) as RecentActivityRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore,
        -- Using string aggregation to collect post titles for visualization
        STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ua.AvgPostScore,
    r.LastActivityDate,
    ph.PostId AS ChildPostId,
    ph.Title AS ChildPostTitle,
    ph.Level AS PostLevel
FROM 
    UserEngagement ua
LEFT JOIN 
    RecentActivity r ON ua.UserId = r.OwnerUserId AND r.RecentActivityRank = 1
LEFT JOIN 
    PostHierarchy ph ON ua.TotalPosts > 0 -- Include hierarchy data for users with posts
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ua.TotalPosts DESC, ua.TotalUpvotes DESC;

-- Including NULL logic by filtering out users with zero posts

WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate AS PostCreationDate,
        p.AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        COALESCE(SUM(vote.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(vote.VoteTypeId = 3), 0) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    GROUP BY 
        u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS RecentActivityRank
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate >= CURRENT_DATE - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.UserDisplayName,
        ph.CreationDate AS CloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    u.DisplayName,
    us.TotalPosts,
    us.TotalViews,
    us.TotalUpvotes,
    us.TotalDownvotes,
    p.Title AS RecentPostTitle,
    p.CreationDate AS RecentPostCreationDate,
    cp.CloseReason AS ClosedPostReason,
    cp.CloseDate AS ClosedPostDate,
    rph.PostTitle AS AnswerTitle,
    rph.Level AS AnswerLevel
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    PostActivity p ON u.Id = p.OwnerUserId AND p.RecentActivityRank = 1
LEFT JOIN 
    ClosedPosts cp ON p.PostId = cp.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON p.PostId = rph.AcceptedAnswerId
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.TotalViews DESC, us.TotalUpvotes DESC
LIMIT 100;

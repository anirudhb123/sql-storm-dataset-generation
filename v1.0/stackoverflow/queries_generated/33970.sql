WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get the hierarchy of posts
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostScores AS (
    -- CTE for calculating post scores based on votes
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(v.Id) AS TotalVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title
),
ClosedPosts AS (
    -- CTE to find closed posts with closing reasons
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
UserActivity AS (
    -- CTE to aggregate user activity
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.Id AS PostId,
    p.Title,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalVotes,
    ps.CommentCount,
    COALESCE(cp.CloseReason, 'Open') AS CloseReason,
    u.UserId,
    u.DisplayName AS OwnerName,
    ua.PostCount AS OwnerPostCount,
    ua.TotalViews AS OwnerTotalViews,
    ua.AverageScore AS OwnerAverageScore,
    r.Level AS PostLevel
FROM 
    Posts p
LEFT JOIN 
    PostScores ps ON ps.Id = p.Id
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RecursivePostHierarchy r ON r.Id = p.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

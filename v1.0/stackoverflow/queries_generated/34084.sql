WITH RecursivePostHierarchy AS (
    -- CTE to get post hierarchy
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserActivity AS (
    -- CTE to summarize user activities
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
PostVoteSummary AS (
    -- CTE to summarize vote counts per post
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id
),
PostStatistics AS (
    -- CTE to combine posts and their statistics
    SELECT 
        ph.PostId,
        ph.Title,
        ps.UpVotes,
        ps.DownVotes,
        ps.CloseVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY ph.Level ORDER BY ps.UpVotes DESC) AS Rank
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        PostVoteSummary ps ON ph.PostId = ps.PostId
    LEFT JOIN 
        Comments c ON c.PostId = ph.PostId
    GROUP BY 
        ph.PostId, ph.Title, ps.UpVotes, ps.DownVotes, ps.CloseVotes, ph.Level
)

SELECT 
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBounties,
    p.PostId,
    p.Title AS PostTitle,
    p.UpVotes,
    p.DownVotes,
    p.CloseVotes,
    p.CommentCount,
    p.Rank
FROM 
    PostStatistics p
JOIN 
    UserActivity ua ON ua.TotalPosts > 0
JOIN 
    Users u ON u.Id = p.PostId
WHERE 
    p.Rank <= 5 -- Top 5 posts per level
ORDER BY 
    p.Title, ua.TotalBounties DESC;

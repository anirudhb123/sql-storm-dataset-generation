WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Depth,
        CAST(p.Title AS VARCHAR(300)) AS PostTitle
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        r.Depth + 1,
        CAST(r.PostTitle + ' -> ' + p.Title AS VARCHAR(300))
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
HighEngagementUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalVotes,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalVotes DESC, UpVotes DESC) AS EngagementRank
    FROM 
        UserEngagement
    WHERE 
        TotalPosts > 5 AND TotalVotes > 10
)
SELECT 
    ph.PostId,
    ph.Depth,
    ph.PostTitle,
    u.DisplayName AS EngagedUser,
    u.TotalPosts,
    u.TotalVotes,
    SUM(p.ViewCount) AS TotalViewCount,
    (SELECT COUNT(*) FROM Comments cm WHERE cm.PostId = ph.PostId) AS CommentCount
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    Posts p ON ph.PostId = p.Id
LEFT JOIN 
    HighEngagementUsers u ON p.OwnerUserId = u.UserId
GROUP BY 
    ph.PostId, ph.Depth, ph.PostTitle, u.DisplayName, u.TotalPosts, u.TotalVotes
HAVING 
    COUNT(p.Id) > 1
ORDER BY 
    ph.Depth ASC, TotalViewCount DESC;

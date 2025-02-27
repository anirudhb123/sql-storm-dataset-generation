WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Starting point for root posts

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        Count(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'  -- Recent votes in the last 30 days
    GROUP BY 
        v.PostId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate >= NOW() - INTERVAL '60 days'  -- Active users in the last 60 days
),
PostCommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(ph.ParentId, 0) AS ParentId,
    ph.Level,
    v.VoteCount,
    v.UpVotes,
    v.DownVotes,
    c.CommentCount,
    c.LastCommentDate,
    u.DisplayName AS ActiveUser,
    u.Reputation,
    u.Views
FROM 
    Posts p
LEFT JOIN 
    RecursivePostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN 
    RecentVotes v ON p.Id = v.PostId
LEFT JOIN 
    PostCommentStats c ON p.Id = c.PostId
LEFT JOIN 
    ActiveUsers u ON u.Rank <= 10  -- Top 10 active users
WHERE 
    p.CreationDate >= '2021-01-01'  -- Filter for posts created after a specific date
ORDER BY 
    p.Id;

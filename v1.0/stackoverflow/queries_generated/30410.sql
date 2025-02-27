WITH RecursivePostPaths AS (
    -- CTE to find the path of parent-child relationships in posts
    SELECT 
        Id AS PostId,
        ParentId,
        1 AS Level,
        Title,
        OwnerUserId,
        CreationDate
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        r.Level + 1,
        p.Title,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        RecursivePostPaths r ON p.ParentId = r.PostId
),
UserVotes AS (
    -- Aggregate votes per user per post
    SELECT 
        postId,
        UserId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        postId, UserId
),
PostMetrics AS (
    -- Calculate metrics for each post
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(COALESCE(ph.CreationDate, '1900-01-01')) AS LastEditDate,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        UserVotes v ON v.postId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        p.Id, p.OwnerUserId
),
RankedPosts AS (
    -- Ranking posts based on engagement metrics
    SELECT 
        pm.PostId,
        pm.OwnerUserId,
        pm.UpVotes,
        pm.DownVotes,
        pm.CommentCount,
        pm.EditCount,
        pm.LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY pm.OwnerUserId ORDER BY pm.UpVotes DESC, pm.CommentCount DESC) AS PostRank
    FROM 
        PostMetrics pm
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(rp.UpVotes, 0) AS UserUpVotes,
    COALESCE(rp.DownVotes, 0) AS UserDownVotes,
    u.Reputation,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id AND p.CreationDate >= NOW() - INTERVAL '1 year') AS RecentPostCount,
    ARRAY_AGG(rp.PostId) AS UserPosts
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    u.Reputation > 100 AND
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) >= 1 -- Gold badge check
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT rp.PostId) > 0
ORDER BY 
    UserUpVotes DESC, TotalPosts DESC;

WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserActivity AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, 
        u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Close, Reopen, Delete, Undelete
)
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS UserName,
    u.TotalPosts,
    u.Upvotes,
    u.Downvotes,
    r.Level,
    COUNT(DISTINCT ph.PostId) AS HistoryCount,
    MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS LastCloseReason,
    MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Comment END) AS LastReopenReason
FROM 
    TopPosts p
JOIN 
    UserActivity u ON p.Id = u.Id -- Join with user activity to include user information
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.Id
LEFT JOIN 
    PostHistories ph ON p.Id = ph.PostId AND ph.RecentHistory = 1
WHERE 
    u.TotalPosts > 0 
GROUP BY 
    p.Title, u.DisplayName, u.TotalPosts, u.Upvotes, u.Downvotes, r.Level
ORDER BY 
    u.Upvotes - u.Downvotes DESC, 
    p.Score DESC;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Top-level posts
    
    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
RecentPostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
RankedUserActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.Questions,
        ua.Answers,
        ua.TotalVotes,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS UserRank,
        NTILE(5) OVER (ORDER BY ua.TotalVotes DESC) AS VoteBucket
    FROM 
        UserActivity ua
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    up.DisplayName AS OwnerDisplayName,
    up.TotalPosts AS OwnerTotalPosts,
    r.LastEditDate,
    r.EditCount,
    r.EditTypes,
    ra.UserRank,
    ra.VoteBucket
FROM 
    PostHierarchy ph
LEFT JOIN 
    Posts p ON ph.PostId = p.Id
LEFT JOIN 
    Users up ON p.OwnerUserId = up.Id
LEFT JOIN 
    RecentPostHistories r ON p.Id = r.PostId
LEFT JOIN 
    RankedUserActivity ra ON up.Id = ra.UserId
WHERE 
    ph.Level <= 2  -- limit the hierarchy to 2 levels deep
    AND (up.Reputation IS NULL OR up.Reputation > 1000)  -- Filter users with unknown reputation or reputation > 1000
ORDER BY 
    ph.Level, r.LastEditDate DESC;

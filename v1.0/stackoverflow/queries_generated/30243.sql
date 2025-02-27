WITH RecursiveTagHierarchy AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        t.Count,
        0 AS Level
    FROM 
        Tags t
    WHERE 
        t.IsModeratorOnly = 0
    
    UNION ALL
    
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        Level + 1
    FROM 
        Tags t
    INNER JOIN 
        RecursiveTagHierarchy rth ON t.ExcerptPostId = rth.TagId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostRankings AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL AND 
        p.ViewCount > 100
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title AS PostTitle,
        p.Body,
        p.LastActivityDate,
        p.CreationDate AS PostCreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS UpdateRank
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    u.TotalBountyAmount,
    u.BadgeCount,
    p.PostId,
    p.Title AS PostTitle,
    p.ViewCount,
    p.Score,
    th.TagName,
    rth.Level AS TagLevel,
    ph.CreationDate AS LastHistoryChange,
    ph.UserId AS LastEditorUserId
FROM 
    UserReputation u
JOIN 
    PostRankings p ON u.Reputation > 100 AND u.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts)
LEFT JOIN 
    RecursiveTagHierarchy rth ON POSITION(',' || rth.TagId IN ',' || p.Id || ',') > 0
LEFT JOIN 
    RecentPostHistory ph ON p.PostId = ph.PostId
WHERE 
    u.BadgeCount > 0 AND
    (ph.UserId IS NULL OR ph.UpdateRank = 1)
ORDER BY 
    u.Reputation DESC, 
    p.Score DESC, 
    ph.CreationDate DESC
LIMIT 100;

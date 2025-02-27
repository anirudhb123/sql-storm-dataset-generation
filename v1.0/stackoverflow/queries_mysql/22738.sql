
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(MAX(p.Score), 0) AS MaxPostScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseActions,
        COUNT(*) AS EditedActions
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) OR ph.PostHistoryTypeId = 24
    GROUP BY 
        ph.PostId
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.MaxPostScore,
    ur.BadgeCount,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBounties,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    COALESCE(phc.CloseActions, 0) AS CloseActions,
    COALESCE(phc.EditedActions, 0) AS EditedActions,
    CASE 
        WHEN COALESCE(phc.CloseActions, 0) > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN pp.PostRank = 1 THEN 'Latest'
        ELSE 'Older'
    END AS PostRecency
FROM 
    UserReputation ur
JOIN 
    UserActivity ua ON ur.UserId = ua.UserId
LEFT JOIN 
    RankedPosts pp ON ur.UserId = pp.OwnerUserId AND pp.PostRank <= 3
LEFT JOIN 
    PostHistoryCounts phc ON pp.PostId = phc.PostId
WHERE 
    ur.Reputation > (
        SELECT AVG(Reputation) FROM Users
    )
OR 
    EXISTS (
        SELECT 1 
        FROM Badges b 
        WHERE b.UserId = ur.UserId AND b.Class = 1
    )
ORDER BY 
    ur.Reputation DESC,
    pp.CreationDate DESC
LIMIT 100;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
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
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS CloseActions,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 24) AS EditedActions
    FROM 
        PostHistory ph
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
    phc.CloseActions,
    phc.EditedActions,
    CASE 
        WHEN phc.CloseActions > 0 THEN 'Closed'
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

This SQL query incorporates various advanced features and constructs, including Common Table Expressions (CTEs), window functions for ranking posts, conditional counting using `FILTER`, and coalescence to deal with potential NULL values. It combines user attributes, post history, and reputation metrics to generate a rich dataset for performance benchmarking or analytical purposes.

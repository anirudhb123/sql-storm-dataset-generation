WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, GETDATE()) 
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation >= 1000 -- only users with high reputation
    GROUP BY 
        u.Id, u.Reputation
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ur.Reputation,
        COALESCE(cr.CloseReasonCount, 0) AS CloseCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        CloseReasonCounts cr ON rp.PostId = cr.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Score,
    pa.Reputation,
    pa.CloseCount,
    pa.BadgeNames
FROM 
    PostAnalytics pa
WHERE 
    pa.CloseCount = 0 -- Only include posts that have not been closed
    AND pa.Reputation >= 1000 -- Filter for users with high reputation
ORDER BY 
    pa.Score DESC, 
    pa.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY; -- Pagination to limit results

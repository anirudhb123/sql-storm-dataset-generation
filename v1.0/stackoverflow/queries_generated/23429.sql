WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostConnections AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS CloseCount, 
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::INT = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    up.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(pc.RelatedPostCount, 0) AS RelatedPostCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = rp.PostId 
     AND c.CreationDate >= NOW() - INTERVAL '1 month') AS RecentComments
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    PostConnections pc ON rp.PostId = pc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    up.Reputation > (
        SELECT AVG(Reputation) FROM UserReputation
    )
    AND rp.rn = 1
ORDER BY 
    up.Reputation DESC, 
    rp.Score DESC
LIMIT 10;

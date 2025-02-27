WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        CASE 
            WHEN p.LastActivityDate IS NULL THEN 'Inactive'
            WHEN p.LastActivityDate >= NOW() - INTERVAL '30 days' THEN 'Active'
            ELSE 'Older'
        END AS ActivityStatus
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
        AND p.ViewCount > 0
),
BadgesCount AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 OR b.Class = 2  -- Gold or Silver badges
    GROUP BY 
        b.UserId
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserDisplayName,
    up.Reputation,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    uph.HistoryCount,
    uph.LastHistoryDate,
    rp.ActivityStatus,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Answered'
        ELSE 'Unanswered'
    END AS PostStatus
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.UserPostRank = 1 
LEFT JOIN 
    BadgesCount bc ON up.Id = bc.UserId
LEFT JOIN 
    PostHistoryCounts uph ON rp.PostId = uph.PostId
WHERE 
    (rp.ViewCount > 100 OR up.Reputation > 500)
    AND (rp.LastActivityDate >= NOW() - INTERVAL '1 year' OR up.LastAccessDate >= NOW() - INTERVAL '1 year')
    AND (up.Location IS NULL OR up.Location NOT LIKE '%Unknown%')
ORDER BY 
    up.Reputation DESC, 
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;

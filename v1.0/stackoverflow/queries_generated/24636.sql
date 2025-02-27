WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
), 

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    AND 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
),

EnhancedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        COALESCE(cp.ClosedDate, 'No Closure') AS ClosureDate,
        COALESCE(cp.CloseReason, 'N/A') AS ReasonForClosure
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)

SELECT 
    ep.PostId,
    ep.Title,
    ep.CreationDate,
    ep.ViewCount,
    ep.OwnerDisplayName,
    ep.CommentCount,
    ep.ClosureDate,
    ep.ReasonForClosure,
    CASE 
        WHEN ep.ViewCount > 1000 THEN 'High Traffic'
        WHEN ep.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Traffic'
        ELSE 'Low Traffic'
    END AS TrafficLabel
FROM 
    EnhancedPosts ep
WHERE 
    ep.Rank <= 5 -- top 5 per PostType
ORDER BY 
    ep.ViewCount DESC;

-- The below portion is example `UNION` query to pull in some unique badge-related analytics

UNION

SELECT
    b.UserId,
    NULL AS Title,
    NULL AS CreationDate,
    SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 ELSE 1 END) AS TotalBadges,
    u.DisplayName AS OwnerDisplayName,
    NULL AS CommentCount,
    NULL AS ClosureDate,
    NULL AS ReasonForClosure,
    CASE 
        WHEN SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) > 0 THEN 'Gold Badge Holder' 
        ELSE 'Non-Gold Badge Holder' 
    END AS BadgeStatus
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.UserId, u.DisplayName
HAVING 
    AVG(u.Reputation) >= 1000
ORDER BY 
    TotalBadges DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT b.Class) AS UniqueBadgeClasses
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment as CloseReason,
        ph.CreationDate as CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed Posts
    AND 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    up.UserId,
    up.DisplayName,
    COUNT(DISTINCT p.PostId) AS TotalPosts,
    SUM(CASE WHEN r.Rank <= 3 THEN 1 ELSE 0 END) AS TopPostsCount,
    ub.BadgeCount,
    ub.UniqueBadgeClasses,
    COUNT(DISTINCT cp.PostId) AS ClosedPostCount,
    STRING_AGG(DISTINCT cp.CloseReason, ', ') FILTER (WHERE cp.CloseReason IS NOT NULL) AS CloseReasons,
    SUM(COALESCE(ph.ChangeCount, 0)) AS TotalChanges
FROM 
    Users up
LEFT JOIN 
    RankedPosts r ON up.Id = r.OwnerUserId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON up.Id = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId) 
LEFT JOIN 
    PostHistoryData ph ON up.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
WHERE 
    up.Reputation > 100 -- Only users with reputation greater than 100
GROUP BY 
    up.UserId, up.DisplayName, ub.BadgeCount, ub.UniqueBadgeClasses
ORDER BY 
    TotalPosts DESC, BadgeCount DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13, 14) -- Closed, Reopened, Deleted, Undeleted, Locked
),
ClosedPosts AS (
    SELECT 
        DISTINCT ph.PostId,
        ph.Comment AS CloseReason,
        p.Title
    FROM 
        PostHistoryData ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Only closed posts
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(uBad.BadgeCount, 0) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewPosts
    FROM 
        Users u
    LEFT JOIN 
        UserBadges uBad ON u.Id = uBad.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UniqueTags AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT unnest(string_to_array(p.Tags, '>'))) AS UniqueTagCount
    FROM 
        Posts p
    GROUP BY 
        p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.TotalPosts,
    us.TotalViews,
    us.HighViewPosts,
    COALESCE(cp.CloseReason, 'No Closure') AS CloseReason,
    COUNT(DISTINCT ut.PostId) AS UniqueTaggedPosts
FROM 
    UserStats us
LEFT JOIN 
    ClosedPosts cp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
LEFT JOIN 
    UniqueTags ut ON ut.PostId = us.TotalPosts
WHERE 
    us.Reputation > 1000
    AND (us.BadgeCount > 1 OR us.TotalPosts > 5)
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.BadgeCount, us.TotalPosts, us.TotalViews, us.HighViewPosts, cp.CloseReason
ORDER BY 
    us.Reputation DESC, us.TotalViews DESC NULLS LAST;


WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.LastActivityDate
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount, 
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostHistoryFiltered AS (
    SELECT 
        ph.PostId, 
        ph.UserId, 
        ph.CreationDate, 
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
        AND ph.CreationDate >= NOW() - INTERVAL '1 year'
), 
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        COUNT(ph.PostId) AS ClosureCount
    FROM 
        Posts p
    JOIN 
        PostHistoryFiltered ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)

SELECT 
    up.DisplayName, 
    up.Reputation, 
    rp.Title AS RecentPostTitle, 
    rp.CreationDate AS PostCreationDate,
    ub.BadgeCount, 
    ub.MaxBadgeClass, 
    COALESCE(cp.ClosureCount, 0) AS TotalClosures
FROM 
    Users up
JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.ClosedPostId
WHERE 
    up.Reputation > (
        SELECT AVG(Reputation) FROM Users
    )
ORDER BY 
    up.Reputation DESC;

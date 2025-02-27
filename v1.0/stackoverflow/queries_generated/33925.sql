WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100 -- Only consider users with reputation greater than 100
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryClosed AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.CreationDate AS CloseDate,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Only closed posts
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CloseDate,
        ph.UserDisplayName,
        ph.Comment,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COALESCE(bc.BadgeCount, 0) AS UserBadges,
        ROW_NUMBER() OVER (ORDER BY ph.CloseDate DESC) AS CloseRank
    FROM 
        PostHistoryClosed ph
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    LEFT JOIN 
        UserReputation bc ON u.Id = bc.UserId
    WHERE 
        ph.CloseDate > NOW() - INTERVAL '30 days'
),
TopClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        r.Score,
        cp.CloseDate,
        cp.UserDisplayName,
        cp.UserReputation,
        cp.UserBadges,
        cp.Comment
    FROM 
        RankedPosts r
    JOIN 
        Posts p ON r.Id = p.Id
    JOIN 
        RecentClosedPosts cp ON p.Id = cp.PostId
    WHERE 
        cp.CloseRank <= 10
)
SELECT 
    tcp.PostId,
    tcp.Title,
    tcp.ViewCount,
    tcp.Score,
    tcp.CloseDate,
    tcp.UserDisplayName,
    tcp.UserReputation,
    tcp.UserBadges,
    tcp.Comment,
    CASE 
        WHEN tcp.UserBadges > 5 THEN 'Highly regards user'
        WHEN tcp.UserBadges BETWEEN 1 AND 5 THEN 'Moderately regarded user'
        ELSE 'New user'
    END AS UserCategory
FROM 
    TopClosedPosts tcp
ORDER BY 
    tcp.CloseDate DESC;

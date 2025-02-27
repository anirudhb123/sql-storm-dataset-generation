WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.OwnerUserId IS NOT NULL
),
PostStats AS (
    SELECT 
        up.UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users up
    LEFT JOIN 
        Posts p ON up.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        up.Reputation > 1000
    GROUP BY 
        up.UserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    ps.PostCount,
    ps.Upvotes,
    ps.Downvotes,
    ub.BadgeNames,
    COALESCE(rp.Title, 'No recent posts') AS RecentPostTitle,
    COALESCE(rp.CreationDate, 'N/A') AS RecentPostDate
FROM 
    Users u
LEFT JOIN 
    PostStats ps ON u.Id = ps.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank = 1
WHERE 
    u.Reputation > 5000
ORDER BY 
    ps.PostCount DESC NULLS LAST,
    u.DisplayName;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.Location,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, u.Location
), ActiveBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= DATEADD(year, -2, GETDATE()) -- Badges granted in the last 2 years
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    rb.Reputation,
    ub.BadgeNames,
    ub.BadgeCount,
    rp.CommentCount,
    COALESCE(rb.TotalPosts, 0) AS TotalPosts,
    COALESCE(rb.NegativePostsCount, 0) AS NegativePostsCount,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostRankIndicator
FROM 
    RankedPosts rp
JOIN 
    UserReputation rb ON rp.OwnerUserId = rb.UserId
LEFT JOIN 
    ActiveBadges ub ON ub.UserId = rp.OwnerUserId
WHERE 
    rb.Reputation > 500 -- Only include users with reputation greater than 500
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY; -- Paginate results for performance benchmarking

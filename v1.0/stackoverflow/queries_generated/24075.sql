WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT pht.Name) AS PostHistoryTypes,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    u.DisplayName AS UserDisplayName,
    ub.BadgeCount,
    ub.BadgeNames,
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ph.PostHistoryTypes,
    ph.LastEditDate
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostID = ph.PostId
WHERE 
    rp.ViewRank <= 3 OR rp.Score > 10
ORDER BY 
    ub.BadgeCount DESC, 
    rp.ViewCount DESC, 
    rp.Score ASC
LIMIT 100;

-- Additional complexity: Handling NULL logic and string expressions
SELECT 
    CASE 
        WHEN u.Location IS NULL THEN 'Location not specified'
        ELSE u.Location 
    END AS UserLocation,
    SPLIT_PART(u.AboutMe, ' ', 1) AS FirstWordOfAboutMe,
    COUNT(DISTINCT v.PostId) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT v.PostId) > 10;

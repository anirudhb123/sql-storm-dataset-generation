WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(p.Tags, '>')) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        MIN(p.CreationDate) AS FirstPostDate,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
), UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    ua.PostCount,
    ua.TotalBounty,
    ua.FirstPostDate,
    ua.LastPostDate,
    COALESCE(ub.BadgeList, 'No Badges') AS Badges,
    rp.Title,
    rp.Score,
    rp.TagsArray
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    ua.PostCount > 5
ORDER BY 
    ua.TotalBounty DESC
LIMIT 10;

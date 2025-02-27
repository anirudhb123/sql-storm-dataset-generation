WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Ranking
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Filter for questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Within last year
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostCloseReasons AS (
    SELECT 
        p.Id AS PostId,
        JSON_AGG(cr.Name) AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Only closed posts
    GROUP BY 
        p.Id
)
SELECT 
    up.DisplayName AS UserDisplayName,
    up.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pcr.CloseReasons,
    COUNT(c.Id) AS CommentCount
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostCloseReasons pcr ON rp.Id = pcr.PostId
LEFT JOIN 
    Comments c ON rp.Id = c.PostId 
WHERE 
    (rp.ViewCount > 50 OR ub.GoldBadges > 0) -- Filter condition with NULL logic
    AND rp.Ranking <= 5 -- Top 5 posts by score for each user
GROUP BY 
    up.DisplayName, up.Reputation, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, pcr.CloseReasons
HAVING 
    COUNT(c.Id) < 10 -- Limit to users with fewer than 10 comments on their top posts
ORDER BY 
    up.Reputation DESC, rp.Score DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostsWithLinkInfo AS (
    SELECT 
        p.Id AS PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TopPostCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    SUM(pl.RelatedPostCount) AS TotalRelatedPosts,
    AVG(rp.CommentCount) AS AvgCommentsPerPost
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostsWithLinkInfo pl ON rp.PostId = pl.PostId
WHERE 
    u.Reputation > 1000
    AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    AvgCommentsPerPost DESC
LIMIT 10;

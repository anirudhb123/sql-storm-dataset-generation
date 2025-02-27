WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    COALESCE(
        (SELECT MAX(score) 
         FROM Votes v 
         WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2), 0
    ) AS MaxUpvote,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Badges b 
         WHERE b.UserId = rp.OwnerUserId AND b.Class = 1), 0
    ) AS GoldBadges
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 10;

-- Additionally fetching related posts if available
UNION ALL

SELECT 
    pl.RelatedPostId AS PostId,
    p.Title,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COALESCE(
        (SELECT MAX(score) 
         FROM Votes v 
         WHERE v.PostId = pl.RelatedPostId AND v.VoteTypeId = 2), 0
    ) AS MaxUpvote,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Badges b 
         WHERE b.UserId = u.Id AND b.Class = 1), 0
    ) AS GoldBadges
FROM 
    PostLinks pl
JOIN 
    Posts p ON pl.RelatedPostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    pl.LinkTypeId = 3 AND 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    pl.RelatedPostId, p.Title, u.DisplayName, p.CreationDate, p.Score
ORDER BY 
    p.Score DESC
LIMIT 10;

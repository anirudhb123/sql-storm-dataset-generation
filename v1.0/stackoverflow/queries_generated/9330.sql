WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.CreationDate IS NOT NULL), 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and downvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    ub.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
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
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.rn = 1 AND 
        rp.Score > 0
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.BadgeCount,
    CASE 
        WHEN fp.BadgeCount > 5 THEN 'Expert' 
        ELSE 'Novice' 
    END AS UserLevel,
    CASE 
        WHEN fp.BadgeCount IS NULL THEN 'No badges awarded'
        ELSE fp.BadgeNames
    END AS UserBadges
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC
FETCH FIRST 10 ROWS ONLY;

SELECT 
    p.Id AS PostId,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS Downvotes
FROM 
    Posts p
WHERE 
    p.Score >= 0
EXCEPT
SELECT 
    p.Id AS PostId,
    0 AS Upvotes,
    0 AS Downvotes
FROM 
    Posts p
WHERE 
    p.Score < 0;

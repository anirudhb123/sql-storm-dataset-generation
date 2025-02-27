WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosters AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpvotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        u.Reputation > 1000  -- Only users with high reputation
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
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
    rp.ViewCount,
    rp.CommentCount,
    tp.DisplayName AS TopPoster,
    tp.TotalPosts,
    tp.TotalUpvotes,
    ub.BadgeNames,
    ub.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    TopPosters tp ON rp.OwnerUserId = tp.UserId
LEFT JOIN 
    UserBadges ub ON tp.UserId = ub.UserId
WHERE 
    (rp.Score >= 5 OR rp.CommentCount > 10) -- Posts must have high score or many comments
    AND rp.PostRank <= 3  -- Top 3 posts for each user
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;

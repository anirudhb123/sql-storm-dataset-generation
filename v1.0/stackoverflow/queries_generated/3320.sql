WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    us.UserId,
    us.Reputation,
    us.TotalPosts,
    us.TotalBadges,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    ROW_NUMBER() OVER (PARTITION BY us.UserId ORDER BY rp.Score DESC) AS UserPostRank
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStatistics us ON us.UserId = u.Id
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    us.Reputation DESC, rp.Score DESC;

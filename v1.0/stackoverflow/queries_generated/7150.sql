WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
TopRankedPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount, 
        rp.CreationDate, 
        rp.CommentCount, 
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.VoteCount,
    u.DisplayName AS Owner,
    ub.TotalBadges,
    p.CreationDate
FROM 
    TopRankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
ORDER BY 
    p.Score DESC, p.ViewCount DESC;

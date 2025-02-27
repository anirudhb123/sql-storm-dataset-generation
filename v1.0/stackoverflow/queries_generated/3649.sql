WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
        AND p.Score > 10
    GROUP BY 
        p.Id
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1)::INT, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::INT, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::INT, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        um.UserId,
        um.DisplayName AS UserDisplayName,
        um.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserMetrics um ON u.Id = um.UserId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.UserDisplayName,
    tp.Reputation,
    COALESCE(SUM(v.UserId = u.Id)::INT, 0) AS UserVotes
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId
LEFT JOIN 
    Users u ON v.UserId = u.Id AND v.VoteTypeId = 2
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.UserDisplayName, tp.Reputation
ORDER BY 
    tp.Score DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        RankScore,
        CommentCount,
        Upvotes,
        Downvotes
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class = 1)::int AS GoldBadges,
        SUM(b.Class = 2)::int AS SilverBadges,
        SUM(b.Class = 3)::int AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.CommentCount,
    us.UserId,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    tp.Score DESC, us.GoldBadges DESC, us.SilverBadges DESC;

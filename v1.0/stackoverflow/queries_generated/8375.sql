WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        PostBadges pb ON u.Id = pb.UserId
)
SELECT 
    tp.Title,
    tp.Author,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    us.Reputation,
    us.BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
JOIN 
    Users us ON tp.Author = us.DisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

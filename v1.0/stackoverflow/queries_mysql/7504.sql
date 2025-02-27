
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS UserRank,
        @prev_owner_user_id := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        rp.UserRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank = 1
)
SELECT 
    u.DisplayName AS Owner,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id 
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10;

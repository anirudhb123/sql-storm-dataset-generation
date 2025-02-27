WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    ur.DisplayName AS TopUser,
    ur.Reputation
FROM 
    TopPosts tp
LEFT JOIN 
    Users ur ON tp.OwnerUserId = ur.Id
WHERE 
    ur.Id IS NOT NULL AND
    EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2
    )
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

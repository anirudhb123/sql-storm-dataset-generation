
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    ur.Reputation,
    ur.BadgeCount,
    pc.CommentCount,
    COALESCE(pc.AllComments, 'No comments') AS AllComments
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, ur.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

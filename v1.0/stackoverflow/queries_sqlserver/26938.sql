
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    OUTER APPLY (
        SELECT value AS tag_name
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) AS tag_name
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation
    FROM 
        Users u
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.Tags,
    ur.Reputation
FROM 
    TopPosts tp
JOIN 
    Posts p ON p.Id = tp.PostId
JOIN 
    Users u ON u.Id = p.OwnerUserId
JOIN 
    UserReputation ur ON ur.UserId = u.Id
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

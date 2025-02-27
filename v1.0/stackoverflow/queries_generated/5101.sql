WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1' YEAR
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate,
    rp.RankByScore,
    rp.CommentCount,
    rp.VoteCount,
    pt.Name AS PostTypeName,
    ut.DisplayName AS OwnerName
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostTypeId = pt.Id
JOIN 
    Users ut ON rp.OwnerUserId = ut.Id
WHERE 
    rp.RankByScore <= 5 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

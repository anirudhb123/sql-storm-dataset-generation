
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.OwnerDisplayName 
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
)
SELECT 
    t.Id, 
    t.Title, 
    t.CreationDate, 
    t.Score, 
    t.OwnerDisplayName,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    TopPosts t
LEFT JOIN 
    Votes v ON t.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
GROUP BY 
    t.Id, t.Title, t.CreationDate, t.Score, t.OwnerDisplayName
ORDER BY 
    t.Score DESC, t.CreationDate DESC;

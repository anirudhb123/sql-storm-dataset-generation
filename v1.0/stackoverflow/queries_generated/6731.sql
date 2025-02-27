WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (ORDER BY rp.Rank) AS OverallRank
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.PostTypeName,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(b.BadgeCount, 0) AS TotalBadges
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON tp.PostId = c.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) b ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
WHERE 
    tp.OverallRank <= 20
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;

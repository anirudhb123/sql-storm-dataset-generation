
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
HighScoredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerName,
        @row_number := IF(@prev_owner = rp.OwnerName, @row_number + 1, 1) AS Rank,
        @prev_owner := rp.OwnerName
    FROM 
        RecentPosts rp
    CROSS JOIN (SELECT @row_number := 0, @prev_owner := '') AS vars
    ORDER BY 
        rp.OwnerName, rp.Score DESC
),
TopPosts AS (
    SELECT 
        hsp.Id,
        hsp.Title,
        hsp.CreationDate,
        hsp.ViewCount,
        hsp.Score,
        hsp.OwnerName
    FROM 
        HighScoredPosts hsp
    WHERE 
        hsp.Rank <= 3
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON tp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
WHERE 
    tp.OwnerName IS NOT NULL
ORDER BY 
    tp.Score DESC;

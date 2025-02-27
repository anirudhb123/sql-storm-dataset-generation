WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT * 
    FROM RankedPosts 
    WHERE PostRank = 1
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Class
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Score, 
    tp.CreationDate, 
    tp.OwnerDisplayName, 
    ub.BadgeCount AS TotalBadges,
    ub.Class AS BadgeClass
FROM 
    TopPosts tp
LEFT JOIN 
    UserBadges ub ON tp.OwnerUserId = ub.UserId
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

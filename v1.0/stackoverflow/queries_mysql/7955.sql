
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    COALESCE(tg.TagName, 'No Tags') AS TagName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT 
         pt.Id AS PostId,
         GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagName
     FROM 
         Posts pt
     JOIN 
         (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(pt.Tags, ',', numbers.n), ',', -1)) AS tag
          FROM 
          (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
           UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
          WHERE CHAR_LENGTH(pt.Tags) - CHAR_LENGTH(REPLACE(pt.Tags, ',', '')) >= numbers.n - 1) AS tag
     JOIN 
         Tags t ON t.TagName = tag
     GROUP BY 
         pt.Id) tg ON tp.PostId = tg.PostId
LEFT JOIN 
    (SELECT 
         UserId, COUNT(*) AS BadgeCount
     FROM 
         Badges
     GROUP BY 
         UserId) b ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Users.Id = b.UserId)
ORDER BY 
    tp.Score DESC;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
        AND p.Score IS NOT NULL
        AND p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.CreationDate,
    t.ViewCount,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
    (SELECT COUNT(v.Id) 
     FROM Votes v 
     WHERE v.PostId = t.PostId 
     AND v.VoteTypeId IN (2, 3, 7) 
    ) AS VoteCount,
    (SELECT GROUP_CONCAT(DISTINCT tag.TagName SEPARATOR ', ') 
     FROM Tags tag 
     INNER JOIN (
         SELECT 
             TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Title, ' ', numbers.n), ' ', -1)) AS TagName 
         FROM 
             (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
              UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE 
             CHAR_LENGTH(t.Title) - CHAR_LENGTH(REPLACE(t.Title, ' ', '')) >= numbers.n - 1
     ) AS split_tags ON tag.TagName = split_tags.TagName
    ) AS AssociatedTags
FROM 
    TopPosts t
LEFT JOIN 
    Users u ON t.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
ORDER BY 
    t.Score DESC, 
    t.ViewCount DESC
LIMIT 10;

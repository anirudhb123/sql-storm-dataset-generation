
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        U.DisplayName AS Author, 
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount, 
        COUNT(DISTINCT v.UserId) AS VoteCount,
        PHT.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(DISTINCT v.UserId) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    JOIN 
        PostHistory PHT ON p.Id = PHT.PostId AND PHT.PostHistoryTypeId IN (4, 5, 6) 
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, U.DisplayName, PHT.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, Title, Author, CommentCount, VoteCount, LastEditDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Author, 
    tp.CommentCount, 
    tp.VoteCount, 
    tp.LastEditDate, 
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName, p.Id 
     FROM Posts p
     INNER JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
     ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag_arr ON tp.PostId = tag_arr.Id
LEFT JOIN 
    Tags t ON t.TagName = tag_arr.TagName
GROUP BY 
    tp.PostId, tp.Title, tp.Author, tp.CommentCount, tp.VoteCount, tp.LastEditDate
ORDER BY 
    tp.VoteCount DESC, tp.CommentCount DESC;

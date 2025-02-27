
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (
            SELECT 
                p.Id AS PostId, 
                SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
            FROM 
                Posts p
            JOIN 
                (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
            ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
        ) t ON p.Id = t.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName, p.Tags
), FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.rn = 1
)
SELECT 
    fp.Id, 
    fp.Title, 
    fp.Score, 
    fp.ViewCount, 
    fp.AnswerCount, 
    fp.CommentCount, 
    fp.OwnerDisplayName, 
    fp.TagsList
FROM 
    FilteredPosts fp
WHERE 
    fp.Score > 10 
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 100;

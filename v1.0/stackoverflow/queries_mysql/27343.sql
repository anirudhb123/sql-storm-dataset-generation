
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR) 
    GROUP BY
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
    HAVING
        COUNT(c.Id) > 5 
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Tags,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM
        RankedPosts
    WHERE
        Rank = 1
)
SELECT
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.CommentCount,
    tp.VoteCount,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS RelatedTags,
    CASE 
        WHEN tp.VoteCount > 10 THEN 'Highly Voted'
        WHEN tp.VoteCount BETWEEN 5 AND 10 THEN 'Moderately Voted'
        ELSE 'Less Voted' 
    END AS VoteCategory
FROM
    TopPosts tp
LEFT JOIN
    (SELECT 
         Id, 
         SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
         Posts
     INNER JOIN
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
     ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) t ON t.Id = tp.PostId
GROUP BY
    tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, tp.CommentCount, tp.VoteCount
ORDER BY
    tp.VoteCount DESC, tp.CommentCount DESC
LIMIT 10;

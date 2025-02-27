
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 14) THEN 1 ELSE 0 END) AS UpVotes,    
        SUM(CASE WHEN v.VoteTypeId = 11 THEN 1 ELSE 0 END) AS DownVotes,       
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL 30 DAY) AND
        p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsUsed
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, '><', numbers.n), '><', -1)) AS TagName
     FROM 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
     WHERE 
         CHAR_LENGTH(tp.Tags) - CHAR_LENGTH(REPLACE(tp.Tags, '><', '')) >= numbers.n - 1) AS tag 
ON 
    TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag.TagName
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.CommentCount, tp.UpVotes, tp.DownVotes
ORDER BY 
    tp.UpVotes DESC;

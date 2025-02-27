
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Body,
        Tags,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Body,
    p.Tags,
    p.ViewCount,
    p.Score,
    p.OwnerDisplayName,
    p.CommentCount,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS AssociatedTags,
    (
        SELECT 
            COUNT(*) 
        FROM 
            Votes v 
        WHERE 
            v.PostId = p.PostId 
            AND v.VoteTypeId = 2
    ) AS UpVotes,
    (
        SELECT 
            COUNT(*) 
        FROM 
            Votes v 
        WHERE 
            v.PostId = p.PostId 
            AND v.VoteTypeId = 3
    ) AS DownVotes
FROM 
    TopPosts p
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
     FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
     INNER JOIN 
         TopPosts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag 
    ON TRUE
JOIN 
    Tags t ON t.TagName = tag
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Body, p.Tags, p.ViewCount, p.Score, p.OwnerDisplayName, p.CommentCount
ORDER BY 
    p.Score DESC, p.ViewCount DESC;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        AnswerCount,
        OwnerDisplayName,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
    ORDER BY 
        VoteCount DESC, ViewCount DESC
    LIMIT 10
),
TagInfo AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag 
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.AnswerCount,
    tp.VoteCount,
    ti.Tags
FROM 
    TopPosts tp
LEFT JOIN 
    TagInfo ti ON tp.PostId = ti.PostId
ORDER BY 
    tp.VoteCount DESC;

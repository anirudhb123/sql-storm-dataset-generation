
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS Score,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, CreationDate, OwnerDisplayName, AnswerCount, CommentCount, Score
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
)
SELECT 
    trp.Title,
    trp.CreationDate,
    trp.OwnerDisplayName,
    trp.AnswerCount,
    trp.CommentCount,
    trp.Score,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ',') AS Tags
FROM 
    TopRankedPosts trp
LEFT JOIN 
    ( 
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName, p.Id
        FROM 
            Posts p
        JOIN 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON t.Id = trp.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.CreationDate, trp.OwnerDisplayName, trp.AnswerCount, trp.CommentCount, trp.Score
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC
LIMIT 10;

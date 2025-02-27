
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TagsArray AS (
    SELECT 
        p.PostId, 
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsList
    FROM 
        RankedPosts p
    CROSS JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) as tag
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag
    JOIN 
        Tags t ON t.TagName = tag.tag
    GROUP BY 
        p.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Owner,
        rp.CommentCount,
        rp.AnswerCount,
        ta.TagsList,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC, rp.CreationDate ASC) AS PostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId AND v.VoteTypeId IN (2, 1) 
    JOIN 
        TagsArray ta ON ta.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.Owner, rp.CommentCount, rp.AnswerCount, ta.TagsList
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.TagsList,
    tp.CreationDate,
    tp.Owner,
    tp.CommentCount,
    tp.AnswerCount,
    tp.PostRank
FROM 
    TopPosts tp
WHERE 
    tp.PostRank <= 10
ORDER BY 
    tp.PostRank, tp.CreationDate DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tagRaw ON TRUE
    LEFT JOIN 
        Tags t ON tagRaw = t.TagName
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, t.TagName
),

TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.Tags,
        rp.CommentCount, 
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 3 -- Top 3 posts per tag
)

SELECT 
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    tp.CommentCount,
    tp.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC
LIMIT 10;


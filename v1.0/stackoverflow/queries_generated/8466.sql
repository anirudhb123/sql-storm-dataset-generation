WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.Author,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.Author,
    tp.CommentCount,
    tp.AnswerCount,
    COALESCE(AVG(v.BountyAmount), 0) AS AvgBounty,
    STRING_AGG(distinct t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 8
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, ','))::int)
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.Author, tp.CommentCount, tp.AnswerCount
ORDER BY 
    tp.Score DESC;

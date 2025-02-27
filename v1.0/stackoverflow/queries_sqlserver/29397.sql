
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        CROSS APPLY (SELECT DISTINCT value AS tag FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '>')) AS tag
        JOIN Tags t ON tag.tag = t.TagName
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Author,
        Score,
        ViewCount,
        Tags,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.Author,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    STRING_AGG(tag_name, ', ') AS TagList
FROM 
    TopPosts tp
    CROSS APPLY STRING_SPLIT(tp.Tags, ', ') AS tag_name
GROUP BY 
    tp.PostId, tp.Title, tp.Author, tp.CreationDate, tp.ViewCount, tp.Score, tp.CommentCount, tp.VoteCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

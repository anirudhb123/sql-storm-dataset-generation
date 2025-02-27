
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
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
    tp.CreationDate, 
    tp.ViewCount, 
    tp.Score, 
    tp.CommentCount, 
    tp.VoteCount, 
    Tags AS TagList
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

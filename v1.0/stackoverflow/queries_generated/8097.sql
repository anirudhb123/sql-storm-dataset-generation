WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        U.DisplayName AS Author, 
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount, 
        COUNT(DISTINCT v.UserId) AS VoteCount,
        PHT.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(DISTINCT v.UserId) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    JOIN 
        PostHistory PHT ON p.Id = PHT.PostId AND PHT.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, or Tags
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, U.DisplayName, PHT.CreationDate
),
TopPosts AS (
    SELECT 
        PostId, Title, Author, CommentCount, VoteCount, LastEditDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Author, 
    tp.CommentCount, 
    tp.VoteCount, 
    tp.LastEditDate, 
    string_agg(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    string_to_array(p.Tags, ',') AS tag_arr ON tp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.TagName = tag_arr
GROUP BY 
    tp.PostId, tp.Title, tp.Author, tp.CommentCount, tp.VoteCount, tp.LastEditDate
ORDER BY 
    tp.VoteCount DESC, tp.CommentCount DESC;

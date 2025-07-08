
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ph.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND (ph.PostHistoryTypeId = 5 OR ph.PostHistoryTypeId = 4) 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    CAST(rp.LastEditDate AS STRING) AS LastEditDate,
    p.AnswerCount,
    p.CommentCount,
    p.ViewCount,
    p.FavoriteCount,
    LISTAGG(DISTINCT pt.Name, ', ') WITHIN GROUP (ORDER BY pt.Name) AS PostTypes,
    LISTAGG(DISTINCT lt.Name, ', ') WITHIN GROUP (ORDER BY lt.Name) AS LinkTypes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.Id
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
LEFT JOIN 
    PostTypes pt ON pt.Id = p.PostTypeId
WHERE 
    rp.rn = 1 
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.Tags, rp.OwnerDisplayName, rp.LastEditDate, p.AnswerCount, p.CommentCount, p.ViewCount, p.FavoriteCount
ORDER BY 
    p.ViewCount DESC
LIMIT 10;

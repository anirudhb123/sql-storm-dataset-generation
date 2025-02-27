WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerName,
        CreationDate,
        Score,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    pt.Name AS PostTypeName,
    ph.CreationDate AS LastEditDate,
    ph.UserDisplayName AS LastEditorName
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON tp.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = tp.PostId)
ORDER BY 
    tp.Score DESC, tp.CreationDate ASC;

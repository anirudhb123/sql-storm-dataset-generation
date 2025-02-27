WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.ViewCount IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewRank <= 5
),
PostWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.CreationDate,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.ViewCount, tp.CreationDate, tp.OwnerDisplayName
),
FinalResult AS (
    SELECT 
        pwc.PostId,
        pwc.Title,
        pwc.ViewCount,
        pwc.CreationDate,
        pwc.OwnerDisplayName,
        pwc.CommentCount,
        pt.Name AS PostTypeName,
        ph.UserDisplayName AS LastEditor,
        ph.LastEditDate
    FROM 
        PostWithComments pwc
    JOIN 
        PostTypes pt ON EXISTS (SELECT 1 FROM Posts p WHERE p.Id = pwc.PostId AND p.PostTypeId = pt.Id)
    LEFT JOIN 
        Posts p ON p.Id = pwc.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id)
)
SELECT 
    f.PostId,
    f.Title,
    f.ViewCount,
    f.CreationDate,
    f.OwnerDisplayName,
    f.CommentCount,
    f.PostTypeName,
    f.LastEditor,
    f.LastEditDate
FROM 
    FinalResult f
ORDER BY 
    f.ViewCount DESC;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS APPLY (
        SELECT 
            value AS TagName 
        FROM 
            STRING_SPLIT(p.Tags, ',') 
    ) AS t
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    ISNULL(pc.CommentCount, 0) AS TotalComments,
    ISNULL(pt.Tags, 'No Tags') AS Tags,
    tp.OwnerDisplayName
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    PostTags pt ON tp.PostId = pt.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

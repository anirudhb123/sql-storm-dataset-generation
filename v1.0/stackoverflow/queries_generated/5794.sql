WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  -- Only Questions and Answers
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        pHD.EditCount,
        pHD.LastEditDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails pHD ON rp.PostId = pHD.PostId
    WHERE 
        rp.Rank <= 10  -- Top 10 posts
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.EditCount,
    tp.LastEditDate,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    PostsTags pt ON tp.PostId = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.AnswerCount, tp.EditCount, tp.LastEditDate
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY T.TagName ORDER BY p.Score DESC) AS RankWithinTag
    FROM 
        Posts p
    JOIN 
        Tags T ON p.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND  -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created in the last year
    GROUP BY 
        p.Id, T.TagName, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        t.TagName
    FROM 
        RankedPosts rp
    JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        rp.RankWithinTag <= 5  -- Top 5 ranked posts within their tags
)
SELECT 
    tp.Title,
    tp.Body,
    tp.TagName,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(v.Id) AS UpVotes,
    COUNT(DISTINCT CASE WHEN bh.PostHistoryTypeId IN (10, 11) THEN bh.Id END) AS CloseReopenCount
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Upvotes
LEFT JOIN 
    PostHistory bh ON bh.PostId = p.Id
GROUP BY 
    tp.Title, tp.Body, tp.TagName, tp.CreationDate, tp.ViewCount, tp.Score, tp.CommentCount, u.DisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

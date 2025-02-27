WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId -- For counting answers
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tagArray ON true
    LEFT JOIN 
        Tags t ON tagArray.tagName = t.TagName -- Joining on tags
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filtering posts from the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, pt.Name
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.AnswerCount,
        pt.Name AS PostType 
    FROM 
        RankedPosts rp 
    JOIN 
        PostTypes pt ON rp.PostId = pt.Id
    WHERE 
        rp.PostRank <= 5 -- Limit to top 5 posts per type
)
SELECT 
    u.DisplayName AS Author,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.AnswerCount,
    tp.PostType,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId -- Counting badges for users
GROUP BY 
    u.DisplayName, tp.Title, tp.Score, tp.ViewCount, tp.CommentCount, tp.AnswerCount, tp.PostType
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

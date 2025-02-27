WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5  -- Top 5 most viewed questions by tag
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.AnswerCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ARRAY_AGG(DISTINCT bh.Name) AS BadgesEarned
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes bh ON ph.PostHistoryTypeId = bh.Id 
WHERE 
    b.Date >= tp.CreationDate
GROUP BY 
    tp.PostId, tp.Title, tp.ViewCount, tp.CommentCount, tp.AnswerCount, tp.OwnerDisplayName
ORDER BY 
    tp.ViewCount DESC;

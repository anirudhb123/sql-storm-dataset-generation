WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerName,
        CreationDate,
        CommentCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1 -- Latest post by user
)

SELECT 
    tp.Title,
    tp.OwnerName,
    tp.CreationDate,
    tp.AnswerCount,
    tp.CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    CASE 
        WHEN tp.AnswerCount > 0 THEN 'Has Answers'
        ELSE 'No Answers'
    END AS AnswerStatus
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    STRING_TO_ARRAY(tp.Tags, ',') AS tagArray ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(both ' ' FROM tagArray)
GROUP BY 
    tp.Title, tp.OwnerName, tp.CreationDate, tp.AnswerCount, tp.CommentCount
ORDER BY 
    tp.CreationDate DESC
LIMIT 10;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '2 months'
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        rp.PostType,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Get top 5 posts for each type
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.AnswerCount,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(tp.Tags, '<>')) AS TagName
    ) t ON TRUE
GROUP BY 
    tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CommentCount, tp.AnswerCount
ORDER BY 
    tp.CreationDate DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        Tags,
        CommentCount
    FROM 
        RankedPosts 
    WHERE 
        RowNum = 1
    ORDER BY 
        Score DESC, ViewCount DESC
    LIMIT 10
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.Tags,
    tp.CommentCount,
    COALESCE(ph.RevisionGuid, 'No History') AS RevisionGUID,
    COUNT(DISTINCT ph.Id) AS HistoryCount,
    MAX(ph.CreationDate) AS LastEditDate,
    STRING_AGG(DISTINCT CONCAT(ph.UserDisplayName, ': ', ph.Comment), '; ') AS EditComments
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName, tp.Tags
ORDER BY 
    tp.Score DESC;

This SQL query benchmarks string processing and performs several operations on the provided data schema, aiming to identify the top 10 questions based on score and view count. It aggregates tag data from the `Tags` table and includes comments from the `PostHistory` table. Additionally, it displays detailed information about each question, including the number of historical revisions related to each post.

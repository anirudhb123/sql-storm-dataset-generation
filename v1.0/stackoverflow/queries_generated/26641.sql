WITH StringProcessor AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ph.Comments,
        ph.EditedText,
        ARRAY_AGG(DISTINCT t.TagName) AS ProcessedTags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount,
        STRING_AGG(DISTINCT SHOW_REASON(ph.Comment, ph.PostHistoryTypeId), ', ') AS CloseReasons
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN (
        SELECT 
            ph.PostId,
            ph.Comment,
            ph.PostHistoryTypeId,
            ph.CreationDate,
            ph.Text AS EditedText
        FROM 
            PostHistory ph
        WHERE 
            ph.PostHistoryTypeId IN (4, 5, 24) -- Considering title edits, body edits, and suggestions
    ) ph ON ph.PostId = p.Id
    LEFT JOIN 
        LATERAL (
            SELECT 
                DISTINCT t.TagName
            FROM 
                Tags t
            WHERE 
                t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')))
        ) AS t ON TRUE
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, u.DisplayName
)
SELECT 
    PostId,
    Title,
    Body,
    ProcessedTags,
    OwnerDisplayName,
    CreationDate,
    CommentCount,
    EditHistoryCount,
    CloseReasons
FROM 
    StringProcessor 
WHERE 
    ProcessedTags IS NOT NULL
ORDER BY 
    CreationDate DESC
LIMIT 100; 

This SQL query aggregates information about posts in the Stack Overflow schema, focusing on string processing for various attributes. The query retrieves essential details about each post, including its owner, associated tags, edit history, and close reasons, while applying string manipulation techniques. It filters and orders the results based on the creation date, providing a benchmark for processing complex string data like titles, bodies, and tags.

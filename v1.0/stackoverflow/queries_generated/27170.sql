WITH DetailedPostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON tag_array = t.TagName
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(CONCAT(gs.UserDisplayName, ': ', ph.Comment), '; ') AS EditComments
    FROM 
        PostHistory ph
    JOIN 
        Users gs ON ph.UserId = gs.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) -- Type IDs for Title/Body/Tags edits or suggestions
    GROUP BY 
        ph.PostId
)
SELECT 
    dpi.PostId,
    dpi.Title,
    dpi.Body,
    dpi.CreationDate,
    dpi.ViewCount,
    dpi.AnswerCount,
    dpi.OwnerDisplayName,
    dpi.CommentCount,
    dpi.TagsList,
    phs.EditCount,
    phs.LastEditDate,
    phs.EditComments
FROM 
    DetailedPostInfo dpi
LEFT JOIN 
    PostHistorySummary phs ON dpi.PostId = phs.PostId
ORDER BY 
    dpi.ViewCount DESC, dpi.CreationDate DESC
LIMIT 100;

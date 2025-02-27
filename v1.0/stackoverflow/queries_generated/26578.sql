WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate AS PostCreationDate,
        p.LastActivityDate,
        ph.CreationDate AS HistoryCreationDate,
        ppt.Name AS PostType,
        STRING_AGG(DISTINCT h.UserDisplayName, '; ') AS Editors,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostTypes ppt ON p.PostTypeId = ppt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.Body, p.Tags, 
        p.CreationDate, p.LastActivityDate, ppt.Name
),
PostHistoryStats AS (
    SELECT 
        PostId,
        COUNT(*) AS HistoryCount,
        MAX(HistoryCreationDate) AS LastEditDate
    FROM 
        PostDetails
    GROUP BY 
        PostId
),
PostMetrics AS (
    SELECT 
        pd.*,
        phs.HistoryCount,
        phs.LastEditDate,
        CASE 
            WHEN pd.AnswerCount > 0 THEN 'Answered'
            ELSE 'Unanswered'
        END AS Status
    FROM 
        PostDetails pd
    JOIN 
        PostHistoryStats phs ON pd.PostId = phs.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerDisplayName,
    pm.PostCreationDate,
    pm.LastActivityDate,
    pm.HistoryCount,
    pm.LastEditDate,
    pm.Status,
    pm.CommentCount,
    pm.AnswerCount,
    ARRAY_LENGTH(string_to_array(pm.Tags, '>,<'), 1) AS TagCount,
    CASE 
        WHEN pm.Status = 'Answered' THEN 
            ROUND((EXTRACT(EPOCH FROM (NOW() - pm.LastEditDate)) / 86400), 2)
        ELSE 
            NULL
    END AS DaysSinceLastEdit
FROM 
    PostMetrics pm
ORDER BY 
    pm.LastActivityDate DESC, pm.HistoryCount DESC;

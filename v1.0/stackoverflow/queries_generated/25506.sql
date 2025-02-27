WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN a.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName ON TagName IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = TagName
    WHERE 
        p.PostTypeId = 1  -- Filtering for Questions
    GROUP BY 
        p.Id, U.DisplayName
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        p.Title AS PostTitle,
        ph.UserDisplayName AS EditorDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text AS NewValue
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 12)  -- Edit Title, Edit Body, Edit Tags, Post Deleted
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.LastActivityDate,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.AnswerCount,
    pd.TagList,
    COALESCE(phd.EditorDisplayName, 'N/A') AS LastEditedBy,
    COALESCE(phd.EditDate, 'N/A') AS LastEditDate,
    CASE 
        WHEN phd.PostHistoryTypeId = 12 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus,
    COALESCE(phd.Comment, 'No Comments') AS EditComment,
    COALESCE(phd.NewValue, 'No Changes') AS NewValue
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistoryDetails phd ON pd.PostId = phd.PostId
ORDER BY 
    pd.LastActivityDate DESC, pd.Title ASC;

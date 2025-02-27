WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(t.TagName, ', ') ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON true
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag_array) 
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
FilteredPosts AS (
    SELECT 
        pd.*,
        PH.UserDisplayName AS LastEditorDisplayName,
        PH.CreationDate AS LastEditDate,
        PH.Comment AS EditComment,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId IN (6, 24)) AS EditCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostHistory PH ON pd.PostId = PH.PostId
    WHERE 
        Rank = 1 -- Take only the latest entry per unique tag grouping
)
SELECT 
    Title,
    OwnerDisplayName,
    OwnerReputation,
    ViewCount,
    Score,
    CommentCount,
    AnswerCount,
    LastEditorDisplayName,
    LastEditDate,
    EditComment,
    CloseCount,
    EditCount
FROM 
    FilteredPosts
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50;

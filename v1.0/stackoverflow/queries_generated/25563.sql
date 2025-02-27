WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvote
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, ',') t ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId AS EditorUserId,
        ph.UserDisplayName AS EditedBy,
        ph.CreationDate AS EditedOn,
        ph.PostHistoryTypeId,
        pt.Name AS HistoryType,
        ph.Text AS NewValue
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    COALESCE(e.EditedBy, 'Never Edited') AS LastEditedBy,
    COALESCE(e.EditedOn, 'N/A') AS LastEditedOn,
    COALESCE(e.NewValue, 'No changes') AS LastChange,
    e.HistoryType
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails e ON rp.PostId = e.PostId
WHERE 
    rp.RN = 1
ORDER BY 
    rp.CommentCount DESC, rp.VoteCount DESC
LIMIT 100;

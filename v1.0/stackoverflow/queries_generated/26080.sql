WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '><')) AS TagName) t ON true
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserId,
        u.DisplayName AS EditorDisplayName,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 'Closed/Reopened/Deleted'
            ELSE 'Edited'
        END AS ChangeType
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
),
RecentEdits AS (
    SELECT 
        pd.*,
        phd.EditorDisplayName,
        phd.ChangeType,
        ROW_NUMBER() OVER (PARTITION BY pd.PostId ORDER BY phd.HistoryDate DESC) AS rn
    FROM 
        PostDetails pd
    JOIN 
        PostHistoryDetails phd ON pd.PostId = phd.PostId
    WHERE 
        phd.HistoryDate > NOW() - INTERVAL '30 days' -- Only edits in the last 30 days
)

SELECT 
    re.PostId,
    re.Title,
    re.OwnerDisplayName,
    re.CommentCount,
    re.ViewCount,
    re.Score,
    STRING_AGG(DISTINCT re.Tags, ', ') AS Tags,
    re.EditorDisplayName,
    re.ChangeType,
    re.HistoryDate
FROM 
    RecentEdits re
WHERE 
    re.rn = 1
GROUP BY 
    re.PostId, re.Title, re.OwnerDisplayName, 
    re.CommentCount, re.ViewCount, re.Score, 
    re.EditorDisplayName, re.ChangeType, re.HistoryDate
ORDER BY 
    re.HistoryDate DESC;

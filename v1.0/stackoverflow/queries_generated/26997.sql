WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        (
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ) AS CommentCount,
        (
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3) -- Upvotes and downvotes
        ) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TagSummary AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId, 
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(ph.Id) AS TotalEdits,
        STRING_AGG(pt.Name, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.Tags,
    pd.Owner,
    pd.CreationDate,
    pd.LastActivityDate,
    pd.Score,
    pd.CommentCount,
    pd.VoteCount,
    ts.TagName,
    ts.PostCount,
    phs.FirstEditDate,
    phs.LastEditDate,
    phs.TotalEdits,
    phs.ChangeTypes
FROM 
    PostDetails pd
LEFT JOIN 
    TagSummary ts ON pd.Tags LIKE '%' || ts.TagName || '%'
LEFT JOIN 
    PostHistorySummary phs ON pd.PostId = phs.PostId
ORDER BY 
    pd.Score DESC, 
    pd.LastActivityDate DESC;

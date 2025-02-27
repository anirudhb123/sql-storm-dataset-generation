WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_SPLIT(LEFT(p.Tags, LEN(p.Tags) - 1), '>') AS tag_split ON tag_split.value IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag_split.value)
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= '2021-01-01' -- Questions created from 2021 onwards
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, 
        p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName, u.Reputation
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostSummary AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.OwnerReputation,
        pd.CreationDate,
        pd.LastActivityDate,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.Tags,
        COALESCE(SUM(pa.ChangeCount), 0) AS TotalChanges,
        COALESCE(MAX(pa.LastChangeDate), 'N/A') AS LastChangeDate
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostActivity pa ON pd.PostId = pa.PostId
    GROUP BY 
        pd.PostId, pd.Title, pd.OwnerDisplayName, pd.OwnerReputation, 
        pd.CreationDate, pd.LastActivityDate, pd.ViewCount, pd.AnswerCount,
        pd.CommentCount, pd.Tags
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.Tags,
    ps.TotalChanges,
    ps.LastChangeDate,
    DATEDIFF(DAY, ps.CreationDate, GETDATE()) AS DaysSinceCreation,
    DATEDIFF(DAY, ps.LastActivityDate, GETDATE()) AS DaysSinceLastActivity
FROM 
    PostSummary ps
WHERE 
    ps.TotalChanges > 5 -- Posts with significant editing activity
ORDER BY 
    ps.TotalChanges DESC, ps.ViewCount DESC;

WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.ViewCount,
        COALESCE(pa.PostId, 0) AS AcceptedAnswerId,
        ph.CreationDate AS LastEditDate,
        ph.UserId AS LastEditorId,
        ph.UserDisplayName AS LastEditorDisplayName,
        ph.Text AS EditComment,
        ph.PostHistoryTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts pa ON p.AcceptedAnswerId = pa.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.Tags,
        pd.ViewCount,
        RANK() OVER (ORDER BY pd.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY COALESCE(pd.AcceptedAnswerId, 0) DESC) AS AnswerRank
    FROM 
        PostDetails pd
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
TagsSplit AS (
    SELECT 
        pd.PostId,
        unnest(string_to_array(pd.Tags, ', ')) AS Tag
    FROM 
        PostDetails pd
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Tags,
    rp.ViewCount,
    vs.UpVotes,
    vs.DownVotes,
    vs.AcceptedVotes,
    ARRAY_AGG(DISTINCT ts.Tag) AS UniqueTags,
    pd.CreationDate,
    pd.EditComment,
    pd.LastEditDate,
    pd.LastEditorId,
    pd.LastEditorDisplayName
FROM 
    RankedPosts rp
JOIN 
    VoteStatistics vs ON rp.PostId = vs.PostId
JOIN 
    PostDetails pd ON rp.PostId = pd.PostId
LEFT JOIN 
    TagsSplit ts ON pd.PostId = ts.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Tags, rp.ViewCount, 
    vs.UpVotes, vs.DownVotes, vs.AcceptedVotes,
    pd.CreationDate, pd.EditComment, pd.LastEditDate,
    pd.LastEditorId, pd.LastEditorDisplayName
ORDER BY 
    rp.ViewRank, rp.AnswerRank
LIMIT 50;  -- Limiting the results for performance benchmarking

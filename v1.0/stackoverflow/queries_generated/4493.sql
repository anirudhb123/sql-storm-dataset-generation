WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(upvote_count, 0) AS UpVotes,
        COALESCE(downvote_count, 0) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) as Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
        LEFT JOIN (SELECT PostId, COUNT(*) AS upvote_count FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) upvotes ON p.Id = upvotes.PostId
        LEFT JOIN (SELECT PostId, COUNT(*) AS downvote_count FROM Votes WHERE VoteTypeId = 3 GROUP BY PostId) downvotes ON p.Id = downvotes.PostId
        LEFT JOIN unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE
        LEFT JOIN Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
), PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.Rank,
        rp.Tags,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM 
        RankedPosts rp
        LEFT JOIN Posts ah ON rp.PostId = ah.AcceptedAnswerId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.Tags,
    (CASE WHEN pd.AcceptedAnswerId IS NOT NULL THEN 'Accepted' ELSE 'Not Accepted' END) AS AnswerStatus
FROM 
    PostDetails pd
WHERE 
    pd.Rank = 1
ORDER BY 
    pd.Score DESC
LIMIT 10
UNION ALL
SELECT 
    NULL AS PostId,
    'Total Posts' AS Title,
    NULL AS CreationDate,
    COUNT(*) AS Score,
    NULL AS UpVotes,
    NULL AS DownVotes,
    NULL AS Tags,
    NULL AS AnswerStatus
FROM 
    Posts 
WHERE 
    CreationDate >= NOW() - INTERVAL '1 year';

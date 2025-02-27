WITH RankedVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS Upvotes,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY p.Id
),
PostDiscussion AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT pht.Name ORDER BY pht.Id) AS HistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
CombinedData AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(rv.Upvotes, 0) AS Upvotes,
        COALESCE(rv.Downvotes, 0) AS Downvotes,
        COALESCE(pd.CommentCount, 0) AS CommentCount,
        pd.LastCommentDate,
        COALESCE(pHd.HistoryTypes, ARRAY[]::varchar[]) AS HistoryTypes,
        pHd.LastHistoryDate
    FROM Posts p
    LEFT JOIN RankedVotes rv ON p.Id = rv.PostId
    LEFT JOIN PostDiscussion pd ON p.Id = pd.PostId
    LEFT JOIN PostHistoryDetails pHd ON p.Id = pHd.PostId
)
SELECT 
    cdp.PostId,
    cdp.Upvotes,
    cdp.Downvotes,
    cdp.CommentCount,
    cdp.LastCommentDate,
    cdp.HistoryTypes,
    cdp.LastHistoryDate,
    CASE 
        WHEN cdp.Upvotes > cdp.Downvotes THEN 'Positive'
        WHEN cdp.Upvotes < cdp.Downvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus,
    CASE 
        WHEN cdp.CommentCount = 0 THEN 'No comments yet.'
        ELSE 'Comments available.'
    END AS CommentStatus,
    STRING_AGG(DISTINCT COALESCE(cdp.HistoryTypes[i], 'NO_HISTORY') || ' at ' || COALESCE(cdp.LastHistoryDate::date, 'N/A') 
                ORDER BY i) AS ConcatenatedHistory
FROM CombinedData cdp
LEFT JOIN GENERATE_SERIES(1, array_length(cdp.HistoryTypes, 1)) AS i ON true
WHERE cdp.LastCommentDate >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY cdp.PostId, cdp.Upvotes, cdp.Downvotes, cdp.CommentCount, cdp.LastCommentDate, cdp.HistoryTypes, cdp.LastHistoryDate
ORDER BY cdp.Upvotes DESC, cdp.Downvotes ASC
LIMIT 100;

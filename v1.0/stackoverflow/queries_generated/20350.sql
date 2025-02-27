WITH RecursiveVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS VoteOrder
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
CommentSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT c.UserDisplayName, ', ') AS Commenters
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(rv.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(rv.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(cs.CommentCount, 0) AS CommentCount,
        COALESCE(cs.Commenters, 'No comments yet') AS Commenters
    FROM 
        Posts p
    LEFT JOIN 
        RecursiveVoteCounts rv ON p.Id = rv.PostId
    LEFT JOIN 
        CommentSummary cs ON p.Id = cs.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.CommentCount,
    pd.Commenters,
    CASE 
        WHEN pd.UpVoteCount > pd.DownVoteCount THEN 'Positive'
        WHEN pd.UpVoteCount < pd.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    PostDetails pd
WHERE 
    pd.CreationDate > NOW() - INTERVAL '30 days'
    AND NOT EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = pd.PostId 
        AND v.VoteTypeId IN (2, 3)
        AND v.UserId IS NULL -- seeking cases where the user is apparently missing
    )
ORDER BY 
    pd.UpVoteCount DESC,
    pd.CommentCount DESC
LIMIT 50;

-- This query attempts to provide an elaborate overview of posts created in the last 30 days,
-- including recursive counting of votes that considers upvotes and downvotes and aggregates comments
-- while applying a sentiment analysis based on the voting outcomes.
-- Any posts without known user-votes (potential anomalies) are filtered out.

WITH RecursiveCTE AS (
    SELECT 
        Id, 
        Title, 
        AcceptedAnswerId, 
        ParentId, 
        0 AS Level 
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1  -- Only considering questions
    UNION ALL
    SELECT 
        p.Id, 
        p.Title, 
        p.AcceptedAnswerId, 
        p.ParentId, 
        Level + 1 
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COALESCE(a.OwnerDisplayName, 'Community User') AS AcceptedAnswerOwner,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
),
VoteSummary AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
AggregatedResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.AcceptedAnswerOwner,
        pd.CommentCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COUNT(DISTINCT ph.Id) AS PostHistoryCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        VoteSummary vs ON pd.PostId = vs.PostId
    LEFT JOIN 
        PostHistory ph ON pd.PostId = ph.PostId
    LEFT JOIN 
        PostLinks pl ON pd.PostId = pl.PostId
    GROUP BY 
        pd.PostId, pd.Title, pd.CreationDate, pd.Score, pd.AcceptedAnswerOwner, pd.CommentCount
)
SELECT 
    ar.PostId,
    ar.Title,
    ar.CreationDate,
    ar.Score,
    ar.AcceptedAnswerOwner,
    ar.CommentCount,
    ar.UpVotes,
    ar.DownVotes,
    ar.PostHistoryCount,
    ar.RelatedPostsCount,
    (SELECT COUNT(*) FROM Tags WHERE Id IN (SELECT UNNEST(string_to_array(Tags, '<>'))::int FROM Posts WHERE Id = ar.PostId)) ) AS TagCount,
    RANK() OVER (ORDER BY ar.Score DESC) AS Rank
FROM 
    AggregatedResults ar
WHERE 
    ar.CommentCount > 5 -- Filter for posts with more than 5 comments
ORDER BY 
    ar.Score DESC, 
    ar.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY; -- Pagination for the first 100 records

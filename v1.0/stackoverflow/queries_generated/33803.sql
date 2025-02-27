WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find answers related to questions for performance benchmarking
    SELECT 
        Id AS PostId,
        ParentId,
        PostTypeId,
        Score,
        Title,
        CreationDate,
        1 AS Level
    FROM Posts
    WHERE PostTypeId = 1 -- Start with questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.PostTypeId,
        p.Score,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
PostVotes AS (
    -- Aggregate votes for both questions and answers to measure engagement
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
PostMetrics AS (
    -- Combine post data with its hierarchy and vote metrics
    SELECT 
        ph.PostId,
        ph.Title,
        ph.CreationDate,
        ph.Level,
        COALESCE(pv.UpVotes, 0) AS UpVotes,
        COALESCE(pv.DownVotes, 0) AS DownVotes,
        ph.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.PostId) AS CommentCount
    FROM RecursivePostHierarchy ph
    LEFT JOIN PostVotes pv ON ph.PostId = pv.PostId
),
ClosedPosts AS (
    -- Identify posts that have been closed, capturing the close reason
    SELECT 
        ph.PostId,
        ph.Title,
        ph.CreationDate,
        pH.Comment AS CloseReason
    FROM PostHistory pH
    INNER JOIN Posts p ON p.Id = pH.PostId
    WHERE pH.PostHistoryTypeId = 10 -- Post Closed
),
FinalMetrics AS (
    SELECT 
        pm.*,
        CASE 
            WHEN cp.PostId IS NOT NULL THEN 1
            ELSE 0
        END AS IsClosed
    FROM PostMetrics pm
    LEFT JOIN ClosedPosts cp ON pm.PostId = cp.PostId
)
SELECT 
    *,
    (UpVotes - DownVotes) AS NetVotes,
    RANK() OVER (PARTITION BY Level ORDER BY Score DESC) AS ScoreRank
FROM FinalMetrics
WHERE (CreationDate >= NOW() - INTERVAL '1 year') 
  AND (CommentCount > 0 OR IsClosed = 1) -- Filter for active or closed posts
ORDER BY Level, ScoreRank;

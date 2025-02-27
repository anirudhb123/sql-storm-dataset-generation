WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL -- Top-level posts (questions)

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ParentId,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
PostWithDynamics AS (
    SELECT 
        p.*,
        COALESCE(pvs.VoteCount, 0) AS VoteCount,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS HasAcceptedAnswer
    FROM Posts p
    LEFT JOIN PostVoteStatistics pvs ON p.Id = pvs.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
),
PostSummary AS (
    SELECT 
        p.Title,
        p.CreationDate,
        pd.Level,
        p.VoteCount,
        p.UpVotes,
        p.DownVotes,
        closes.FirstClosedDate
    FROM PostWithDynamics p
    LEFT JOIN RecursivePostHierarchy pd ON p.Id = pd.PostId
    LEFT JOIN ClosedPosts closes ON p.Id = closes.PostId
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Level,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    closes.FirstClosedDate,
    CASE 
        WHEN closes.FirstClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM PostSummary ps
WHERE ps.UpVotes >= 5 -- Filtering for popular posts
ORDER BY ps.Level, ps.UpVotes DESC
LIMIT 100;

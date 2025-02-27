WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.ParentId,
        ph.Level + 1 AS Level
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy ph ON a.ParentId = ph.PostId
    WHERE 
        a.PostTypeId = 2  -- Answers
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostStats AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Level,
        pv.UpVotes,
        pv.DownVotes,
        COALESCE(CAST(ROUND(100.0 * pv.UpVotes / NULLIF(pv.UpVotes + pv.DownVotes, 0), 2) AS varchar), '0') AS UpvotePercentage,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM PostHistory phist WHERE phist.PostId = ph.PostId AND phist.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        PostVoteCounts pv ON ph.PostId = pv.PostId
)
SELECT 
    ps.Title,
    ps.Level,
    ps.UpVotes,
    ps.DownVotes,
    ps.UpvotePercentage,
    ps.CommentCount,
    ps.CloseCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation
FROM 
    PostStats ps
LEFT JOIN 
    Users U ON ps.OwnerUserId = U.Id
WHERE 
    ps.Level = 0  -- Only top-level Questions
ORDER BY 
    ps.UpVotes DESC
LIMIT 10;

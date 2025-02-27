WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= now() - INTERVAL '1 year'
          AND p.PostTypeId = 1 -- Only Questions
          AND p.ViewCount IS NOT NULL
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        u.Reputation,
        u.DisplayName
    FROM 
        Votes v
    JOIN 
        Users u ON v.UserId = u.Id
    GROUP BY 
        v.UserId, u.Reputation, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId AS CloserUserId,
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::json->>'CloseReasonId'::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    ru.DisplayName AS TopOwner,
    u.Reputation AS TopOwnerReputation,
    COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(uv.DownVotes, 0) AS TotalDownVotes,
    cp.CloseDate,
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    Users ru ON rp.OwnerUserId = ru.Id
LEFT JOIN 
    UserVotes uv ON ru.Id = uv.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank = 1 -- Select only the top question for each user
    AND (uv.UpVotes IS NULL OR uv.UpVotes > uv.DownVotes) -- Users who have more upvotes than downvotes
ORDER BY 
    rp.ViewCount DESC, 
    rp.Title ASC
FETCH FIRST 100 ROWS ONLY;

-- Explanation of complicated constructs:
-- CTEs are used to rank posts by views, gather user voting information,
-- and retrieve posts that have been closed, correlating them by various edges.
-- We make use of outer joins, null coalescing for safety,
-- and filters to fetch only optimal users with solid reputations
-- while handling complex predicates about vote counting.

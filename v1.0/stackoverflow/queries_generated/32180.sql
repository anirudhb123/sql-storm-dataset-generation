WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Starting from top-level posts (no parent)

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
    GROUP BY 
        ph.PostId
)

SELECT 
    r.PostId,
    r.Title,
    COALESCE(pv.Upvotes, 0) AS Upvotes,
    COALESCE(pv.Downvotes, 0) AS Downvotes,
    COALESCE(pv.TotalVotes, 0) AS TotalVotes,
    COALESCE(cpr.CloseReasons, 'Not Closed') AS CloseReasons,
    r.Level
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    PostVoteSummary pv ON r.PostId = pv.PostId
LEFT JOIN 
    ClosedPostReasons cpr ON r.PostId = cpr.PostId
WHERE 
    r.Level <= 3 -- Limit to maximum 3 levels of hierarchy
ORDER BY 
    r.Level, r.Title;

In this elaborate SQL query:

1. **Recursive CTE (`RecursivePostHierarchy`)** is used to build a hierarchy of posts, starting from top-level posts that have no parent. It captures the parent-child relationship among posts.

2. **Aggregate Functions with Conditional Logic** are utilized in the `PostVoteSummary` CTE to count upvotes and downvotes for each post.

3. **String Aggregation** in `ClosedPostReasons` aggregates the close reason names for posts that have been closed.

4. **Main Query** then combines these CTEs using `LEFT JOIN` to retrieve necessary details about each post, including vote summaries and closure reasons, while applying a predicate to control the depth of the hierarchy.

5. Results are ordered by post level and title. 

6. **NULL Logic** (`COALESCE`) ensures that for posts without votes or those that are not closed, default values are provided.

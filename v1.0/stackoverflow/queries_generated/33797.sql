WITH RecursiveTagInfo AS (
    SELECT 
        Tags.Id AS TagId,
        Tags.TagName,
        Tags.Count,
        Posts.Id AS PostId,
        Posts.Title AS PostTitle,
        Posts.CreationDate AS PostCreationDate,
        1 AS Level
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.ExcerptPostId = Posts.Id
    UNION ALL
    SELECT 
        t.Id AS TagId,
        t.TagName,
        t.Count,
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate AS PostCreationDate,
        ri.Level + 1
    FROM 
        RecursiveTagInfo ri
    JOIN 
        PostLinks pl ON ri.PostId = pl.PostId
    JOIN 
        Posts p ON pl.RelatedPostId = p.Id
    JOIN 
        Tags t ON t.WikiPostId = p.Id
),
AggregatedVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(Id) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostCloseReasons AS (
    SELECT 
        PostId,
        STRING_AGG(DISTINCT CloseReasonTypes.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ON ph.Comment::json->>'CloseReasonId'::int = CloseReasonTypes.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        PostId
)
SELECT 
    rt.TagName,
    rt.Count AS TagUsageCount,
    COALESCE(SUM(av.TotalUpvotes), 0) AS TotalUpvotes,
    COALESCE(SUM(av.TotalDownvotes), 0) AS TotalDownvotes,
    COALESCE(pr.CloseReasons, 'N/A') AS CloseReasons,
    COUNT(DISTINCT rt.PostId) AS RelatedPostCount,
    MIN(rt.PostCreationDate) AS EarliestPostDate,
    MAX(rt.PostCreationDate) AS MostRecentPostDate
FROM 
    RecursiveTagInfo rt
LEFT JOIN 
    AggregatedVotes av ON rt.PostId = av.PostId
LEFT JOIN 
    PostCloseReasons pr ON rt.PostId = pr.PostId
WHERE 
    rt.Level <= 5 AND 
    rt.Count > 0
GROUP BY 
    rt.TagName, rt.Count, pr.CloseReasons
ORDER BY 
    TagUsageCount DESC, TotalUpvotes DESC;

This elaborate SQL query includes:
- A recursive CTE to develop a hierarchy of tags linked to their posts.
- An aggregate CTE to compute total upvotes and downvotes for each post.
- A CTE to collect and group close reasons for each post.
- A main SELECT statement that combines results, using `COALESCE` to handle NULL values and dynamic field aggregation, with filtering and ordering logic for comprehensive analysis.

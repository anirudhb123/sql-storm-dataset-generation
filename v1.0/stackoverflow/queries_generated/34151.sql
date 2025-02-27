WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL 
    
    UNION ALL 
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserPostDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostVoteCounts v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::integer = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed event
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.TotalUpVotes,
    u.TotalDownVotes,
    STRING_AGG(DISTINCT ph.PostId::text || ' - ' || ph.Title, '; ') AS PostsAndIds,
    COALESCE(cr.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    UserPostDetails u
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    RecursivePostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN 
    ClosedPostReasons cr ON p.Id = cr.PostId
WHERE 
    u.Reputation > 1000  -- Only considering users with a reputation over 1000
GROUP BY 
    u.UserId, cr.CloseReasons
ORDER BY 
    u.Reputation DESC;

This SQL query does the following:

1. **Recursive CTE (RecursivePostHierarchy)**: Retrieves the hierarchy of posts, capturing both parent and child relationships.
  
2. **PostVoteCounts**: Counts the upvotes and downvotes per post using conditional aggregation.
  
3. **UserPostDetails**: Aggregates user statistics such as the total number of posts and votes (up and down) per user.
  
4. **ClosedPostReasons**: Aggregates the reasons for closed posts into a comma-separated list for easier readability.

5. **Main SELECT Statement**: Joins the above CTEs to return each user's display name, reputation, total posts, and aggregated votes, while also including information about the posts they own and the reasons for any closed posts.

6. **Filtering and Sorting**: The results are filtered to include only users with a reputation over 1000 and are sorted by reputation in descending order.

This query showcases several SQL features, including CTEs, joins, conditional aggregations, and string aggregation functions, providing a holistic view focused on user contributions and post closure reasons.

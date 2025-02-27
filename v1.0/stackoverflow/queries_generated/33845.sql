WITH RecursivePostHierarchy AS (
    -- Recursively find all child posts for a given parent post
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Top-level posts only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        r.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserEngagement AS (
    -- Aggregate user statistics related to their posts and comments
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    -- Analyze post history changes and count how many posts were closed
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        MAX(ph.CreationDate) AS LastModifiedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ueng.UserId,
    ueng.DisplayName,
    ueng.TotalPosts,
    ueng.TotalComments,
    ueng.UpvotesReceived,
    ueng.DownvotesReceived,
    COALESCE(ph.CloseCount, 0) AS TotalClosedPosts,
    COALESCE(ph.ReopenCount, 0) AS TotalReopenedPosts,
    (
        SELECT 
            COUNT(*) 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = ueng.UserId 
            AND p.CreationDate >= NOW() - INTERVAL '30 day'
    ) AS PostsLast30Days,
    ROW_NUMBER() OVER (ORDER BY ueng.TotalPosts DESC) AS UserRank
FROM 
    UserEngagement ueng
LEFT JOIN 
    PostHistoryAnalysis ph ON ueng.UserId = (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = ph.PostId)
ORDER BY 
    UserRank
LIMIT 10;
This SQL query accomplishes several tasks:
1. **Recursive CTE** (`RecursivePostHierarchy`) to create a hierarchy of posts, allowing insights into post parent-child relationships.
2. **User engagement metrics** aggregated in the `UserEngagement` CTE, collecting statistics on user activity related to posts and comments.
3. **Post history analysis** in the `PostHistoryAnalysis` CTE, counting the number of times posts were closed or reopened.
4. The main query combines user engagement metrics with post history details, providing a comprehensive view of user activity. It includes a rank for users based on their post count and limits results to the top 10 users.

WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        CreationDate,
        OwnerUserId,
        Title,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Starting from top-level questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.CreationDate,
        p.OwnerUserId,
        p.Title,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
AggregatePostStats AS (
    SELECT 
        p.UserId,
        COUNT(*) AS TotalPosts,
        AVG(ps.Upvotes) AS AvgUpvotes,
        AVG(ps.Downvotes) AS AvgDownvotes,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.HistoryCount) AS TotalHistoryChanges
    FROM 
        UserActivity p
    JOIN 
        PostStats ps ON ps.Id IN (SELECT Id FROM Posts WHERE OwnerUserId = p.UserId)
    GROUP BY 
        p.UserId
)
SELECT 
    u.DisplayName,
    aps.TotalPosts,
    aps.AvgUpvotes,
    aps.AvgDownvotes,
    aps.TotalComments,
    aps.TotalHistoryChanges,
    CASE 
        WHEN aps.TotalPosts > 50 THEN 'Veteran User'
        WHEN aps.TotalPosts BETWEEN 20 AND 50 THEN 'Experienced User'
        ELSE 'Novice User'
    END AS UserCategory
FROM 
    AggregatePostStats aps
JOIN 
    Users u ON u.Id = aps.UserId
ORDER BY 
    aps.TotalPosts DESC;

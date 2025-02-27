WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(b.Id, 0)) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON v.PostId = p.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(pc.AnswerCount, 0) AS Answers,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) pc ON pc.ParentId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalComments,
    u.TotalVotes,
    u.TotalBadges,
    ph.Title AS ParentTitle,
    pm.Title AS ChildPostTitle,
    pm.Answers,
    pm.ViewCount,
    pm.Rank
FROM UserActivity u
LEFT JOIN PostHierarchy ph ON u.UserId = ph.Id
LEFT JOIN PostMetrics pm ON pm.PostId = ph.Id
WHERE u.TotalPosts > 10  -- Only users with more than 10 posts
ORDER BY u.TotalVotes DESC, u.DisplayName ASC;

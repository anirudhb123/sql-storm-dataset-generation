
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        @row_number := @row_number + 1 AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    CROSS JOIN (SELECT @row_number := 0) r
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownvoteCount,
        AVG(p.ViewCount) OVER (PARTITION BY p.OwnerUserId) AS AvgViewsPerUser
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        GROUP_CONCAT(pr.Name SEPARATOR ', ') AS CloseReasons
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN CloseReasonTypes pr ON CAST(ph.Comment AS UNSIGNED) = pr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY p.Id, ph.CreationDate
)
SELECT 
    ue.DisplayName, 
    ue.TotalPosts, 
    ue.TotalComments,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.AvgViewsPerUser,
    cp.ClosedDate,
    cp.CloseReasons
FROM UserEngagement ue
JOIN PostStatistics ps ON ue.UserId = ps.PostId
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
WHERE ue.TotalPosts > 5
ORDER BY ue.TotalPosts DESC, ue.TotalComments DESC;

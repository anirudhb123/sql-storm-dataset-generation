WITH RECURSIVE UserActivity AS (
    -- CTE to gather user activity over time
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
        u.CreationDate,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.CreationDate
),
TopUsers AS (
    -- Select the top 10 users by posts created
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        TotalVotes,
        TotalComments,
        CreationDate
    FROM UserActivity
    WHERE ActivityRank <= 10
),
ClosedPosts AS (
    -- CTE to gather all closed post details
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pu.Id AS ClosedByUserId,
        pu.DisplayName AS ClosedByDisplayName,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN Users pu ON ph.UserId = pu.Id
    WHERE ph.PostHistoryTypeId = 10  -- Post Closed
)
-- Final query to extract detailed user and post information
SELECT 
    u.DisplayName AS UserName,
    u.PostsCreated,
    u.TotalVotes,
    u.TotalComments,
    COUNT(cp.PostId) AS ClosedPostCount,
    STRING_AGG(CONCAT(cp.Title, ' (closed on ', TO_CHAR(cp.ClosedDate, 'YYYY-MM-DD'), ' by ', cp.ClosedByDisplayName, ' for reason: ', cp.CloseReason, ')'), '; ') AS ClosedPostsDetails
FROM TopUsers u
LEFT JOIN ClosedPosts cp ON u.UserId = cp.ClosedByUserId
GROUP BY u.UserId, u.DisplayName, u.PostsCreated, u.TotalVotes, u.TotalComments
ORDER BY u.PostsCreated DESC;

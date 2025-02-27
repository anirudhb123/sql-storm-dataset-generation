WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - u.CreationDate))) AS AverageAccountAgeInSeconds
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ARRAY_AGG(DISTINCT tag.TagName) AS Tags,
        COALESCE(UPPER(STRING_AGG(DISTINCT CASE
            WHEN ph.PostHistoryTypeId = 10 THEN cr.Name
            ELSE NULL END, ', ')), 'Not Closed') AS CloseReasons
    FROM Posts p
    LEFT JOIN Tags tag ON tag.Id IN (SELECT unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><'))::int)
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id AND ph.PostHistoryTypeId = 10
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
),
UserPostInteraction AS (
    SELECT
        ua.UserId,
        ua.DisplayName,
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        ARRAY_AGG(DISTINCT CASE WHEN c.UserId IS NOT NULL THEN c.Text END) AS UserComments
    FROM UserActivity ua
    JOIN PostStats ps ON ua.TotalPosts > 0
    LEFT JOIN Comments c ON ps.PostId = c.PostId AND c.UserId = ua.UserId
    GROUP BY ua.UserId, ua.DisplayName, ps.PostId, ps.Title, ps.ViewCount, ps.AnswerCount, ps.CommentCount
)
SELECT
    upi.DisplayName,
    upi.Title AS PostTitle,
    upi.ViewCount,
    upi.AnswerCount,
    upi.CommentCount,
    CASE
        WHEN upi.UserComments IS NOT NULL THEN 'Commented: ' || STRING_AGG(c.Text, '; ') 
        ELSE 'No comments made'
    END AS UserCommentsSummary,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ua.AverageAccountAgeInSeconds
FROM UserPostInteraction upi
JOIN UserActivity ua ON upi.UserId = ua.UserId
ORDER BY ua.TotalPosts DESC, upi.ViewCount DESC;

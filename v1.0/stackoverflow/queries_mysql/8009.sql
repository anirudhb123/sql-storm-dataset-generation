
WITH UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        MAX(p.CreationDate) AS LastPostDate,
        u.Reputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts p
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.AcceptedAnswerId, pt.Name
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.LastActivityDate,
        pd.AcceptedAnswerId,
        pd.PostType,
        pd.CommentCount,
        pd.Upvotes,
        pd.Downvotes,
        @row_number := IF(@current_post_type = pd.PostType, @row_number + 1, 1) AS Ranking,
        @current_post_type := pd.PostType
    FROM PostDetails pd
    CROSS JOIN (SELECT @row_number := 0, @current_post_type := '') AS vars
    ORDER BY pd.PostType, pd.Upvotes DESC
)
SELECT 
    ui.DisplayName,
    tp.Title,
    tp.PostType,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    tp.LastActivityDate,
    (SELECT COUNT(*) FROM Users u WHERE u.Reputation > ui.Reputation) AS HigherReputationCount
FROM UserInteractions ui
JOIN TopPosts tp ON ui.PostCount > 5 AND tp.Ranking <= 10
WHERE tp.LastActivityDate > (NOW() - INTERVAL 30 DAY)
ORDER BY ui.Reputation DESC, tp.Upvotes DESC;

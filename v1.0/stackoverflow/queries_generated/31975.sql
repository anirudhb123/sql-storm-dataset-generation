WITH RecursivePosts AS (
    -- Recursive CTE to find all answers to questions posted by users with high reputation
    SELECT p.Id AS PostId, p.OwnerUserId, p.Title, p.CreationDate, 1 AS Level
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND u.Reputation > 1000  -- Only questions from high-reputation users
    
    UNION ALL
    
    SELECT p.Id AS PostId, p.OwnerUserId, p.Title, p.CreationDate, rp.Level + 1
    FROM Posts p
    JOIN RecursivePosts rp ON p.ParentId = rp.PostId  -- Finding answers to previous questions
    WHERE p.PostTypeId = 2  -- Only answers
),
PostDetails AS (
    -- CTE to get the post details including vote counts and comment counts
    SELECT
        p.Id,
        p.Title,
        rp.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT rp.PostId) AS AnswerCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN RecursivePosts rp ON p.Id = rp.PostId
    GROUP BY p.Id, rp.OwnerUserId, p.Title
),
UserBadges AS (
    -- CTE to get users and their badge counts
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    pd.Title,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.AnswerCount,
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Badge'
        WHEN ub.BadgeCount > 5 THEN 'Many Badges'
        ELSE 'Few Badges'
    END AS BadgeStatus,
    CASE 
        WHEN pd.CommentCount = 0 AND pd.UpVotes > 0 THEN 'No Comments, Some Votes'
        WHEN pd.CommentCount > 0 AND pd.UpVotes = 0 THEN 'Comments without Votes'
        ELSE 'Regular Activity'
    END AS ActivityStatus
FROM PostDetails pd
JOIN UserBadges ub ON pd.OwnerUserId = ub.UserId
ORDER BY pd.UpVotes DESC, pd.CommentCount DESC
LIMIT 10;  -- Limit the results for performance benchmarking

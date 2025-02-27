WITH RecursivePosts AS (
    -- CTE to find the parent posts recursively for answers
    SELECT Id, Title, ParentId, CreationDate, OwnerUserId, 1 AS Level
    FROM Posts
    WHERE ParentId IS NULL  -- Base case: start with top-level posts (questions)

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, p.OwnerUserId, rp.Level + 1
    FROM Posts p
    JOIN RecursivePosts rp ON p.ParentId = rp.Id  -- Recursive case
),
UserReputation AS (
    -- CTE to get the total reputation and badges for users with contributions to posts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostMetrics AS (
    -- CTE to gather metrics on posts along with the latest comment
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(c.CreationDate) AS LastCommentDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
TopPosts AS (
    -- CTE to filter for top posts based on comment count, only questions
    SELECT 
        pm.PostId,
        pm.Title,
        pm.CommentCount,
        pm.UpVotes,
        pm.DownVotes,
        pm.LastCommentDate
    FROM PostMetrics pm
    JOIN Posts p ON pm.PostId = p.Id
    WHERE p.PostTypeId = 1  -- Only questions
    HAVING COUNT(c.Id) > 5  -- Get posts with more than 5 comments
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalReputation,
    up.BadgeCount,
    tp.Title AS TopQuestionTitle,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.LastCommentDate,
    CASE 
        WHEN tp.CommentCount > 10 THEN 'Highly Active'
        WHEN tp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM UserReputation up
LEFT JOIN TopPosts tp ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE up.TotalReputation > 1000  -- Only users with significant reputation
ORDER BY up.TotalReputation DESC, tp.CommentCount DESC;

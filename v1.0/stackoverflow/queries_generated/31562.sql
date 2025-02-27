WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        a.CreationDate,
        a.Score,
        a.ViewCount,
        rp.Level + 1
    FROM Posts a
    JOIN RecursivePosts rp ON a.ParentId = rp.PostID
)

SELECT 
    u.Id AS UserID,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    SUM(CASE WHEN a.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
    SUM(COALESCE(COMMENT_COUNT.comment_count, 0)) AS TotalCommentCount,
    SUM(COALESCE(VOTE_COUNT.upvote_count, 0)) AS TotalUpVotes,
    SUM(COALESCE(VOTE_COUNT.downvote_count, 0)) AS TotalDownVotes
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
LEFT JOIN Posts a ON p.Id = a.ParentId  -- Answers
LEFT JOIN (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS comment_count
    FROM Comments c
    GROUP BY c.PostId
) AS COMMENT_COUNT ON p.Id = COMMENT_COUNT.PostId
LEFT JOIN (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS downvote_count
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
) AS VOTE_COUNT ON p.Id = VOTE_COUNT.PostId
WHERE u.Reputation > 1000  -- Highly reputed users
GROUP BY u.Id
HAVING COUNT(DISTINCT p.Id) > 0  -- Users with at least one question
ORDER BY u.Reputation DESC
LIMIT 10;  -- Top 10 users

WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostID,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    up.DisplayName,
    up.Reputation,
    ub.BadgeCount,
    SUM(pa.CommentCount) AS TotalComments,
    SUM(pa.UpVotes) AS TotalUpVotes,
    SUM(pa.DownVotes) AS TotalDownVotes
FROM Users up
LEFT JOIN UserBadges ub ON up.Id = ub.UserId
LEFT JOIN PostAnalytics pa ON up.Id = pa.OwnerUserId
GROUP BY up.Id, ub.BadgeCount
ORDER BY up.Reputation DESC
LIMIT 10;

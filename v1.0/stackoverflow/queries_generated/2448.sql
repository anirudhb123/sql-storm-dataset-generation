WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000 
        AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL) 
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        vote.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS VoteRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, v.VoteTypeId
),
CombinedMetrics AS (
    SELECT 
        ua.UserId, 
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.Upvotes,
        ua.Downvotes,
        pm.PostId,
        pm.Title,
        pm.CreationDate,
        pm.UpvoteCount,
        pm.DownvoteCount
    FROM UserActivity ua
    LEFT JOIN PostMetrics pm ON ua.UserId = pm.PostId
)
SELECT 
    cm.UserId,
    cm.DisplayName,
    cm.Reputation,
    cm.PostCount,
    cm.QuestionCount,
    cm.AnswerCount,
    COALESCE(cm.Upvotes - cm.Downvotes, 0) AS NetVotes,
    pm.Title,
    pm.CreationDate,
    pm.UpvoteCount,
    pm.DownvoteCount
FROM CombinedMetrics cm
FULL OUTER JOIN PostMetrics pm ON cm.PostId = pm.PostId
WHERE 
    cm.UserId IS NOT NULL OR 
    pm.PostId IS NOT NULL
ORDER BY 
    COALESCE(NetVotes, 0) DESC, 
    cm.Reputation DESC
LIMIT 100;

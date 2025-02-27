WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalPosts,
        (SELECT SUM((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2)) 
         FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalUpVotes,
        (SELECT SUM((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3)) 
         FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalDownVotes
    FROM Users u
),
HighReputationUsers AS (
    SELECT UserId, Reputation, DisplayName, TotalPosts, TotalUpVotes, TotalDownVotes
    FROM UserStats
    WHERE Reputation > 1000
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Posts p2 WHERE p2.ParentId = p.Id), 0) AS AnswerCount
    FROM Posts p
),
ClosedPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        ph.CreationDate AS CloseDate,
        CIRCLE(p.Score) AS PostScore
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN PostMetrics p ON ph.PostId = p.PostId
    WHERE pht.Name = 'Post Closed'
      AND ph.CreationDate < NOW() - INTERVAL '1 year'
),
ActivePostMetrics AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM PostMetrics p
    LEFT JOIN Votes v ON p.PostId = v.PostId
    GROUP BY p.PostId, p.Title, p.CreationDate, p.Score
)
SELECT 
    u.DisplayName,
    up.Reputation,
    p.Title AS PostTitle,
    pm.Title AS PostMetricsTitle,
    COALESCE(a.AnswerCount, 0) AS TotalAnswers,
    COALESCE(c.ClosedPostsCount, 0) AS ClosedPostsCount,
    pm.UpVoteCount,
    pm.DownVoteCount,
    p.Score,
    CASE
        WHEN p.Score > 100 THEN 'Highly Rated'
        WHEN p.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory
FROM HighReputationUsers up
JOIN Posts p ON p.OwnerUserId = up.UserId
LEFT JOIN ActivePostMetrics pm ON p.Id = pm.PostId
LEFT JOIN (SELECT p.OwnerUserId, COUNT(*) AS ClosedPostsCount
            FROM ClosedPosts p
            GROUP BY p.OwnerUserId) AS c ON up.UserId = c.OwnerUserId
LEFT JOIN (SELECT OwnerUserId, COUNT(*) AS AnswerCount
            FROM Posts WHERE PostTypeId = 2
            GROUP BY OwnerUserId) AS a ON up.UserId = a.OwnerUserId
WHERE p.CreationDate >= NOW() - INTERVAL '6 months'
  AND p.Score IS NOT NULL
ORDER BY up.Reputation DESC, p.Score DESC
LIMIT 100;

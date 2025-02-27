WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.CreationDate,
           p.OwnerUserId,
           p.AnswerCount,
           p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions
),
ActiveUsers AS (
    SELECT u.Id,
           u.DisplayName,
           u.Reputation,
           u.LastAccessDate,
           CASE 
               WHEN u.Reputation > 1000 THEN 'High Reputation'
               WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
               ELSE 'Low Reputation'
           END AS ReputationCategory
    FROM Users u
    WHERE u.LastAccessDate > NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT b.UserId,
           COUNT(b.Id) AS BadgeCount,
           STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
ClosedPosts AS (
    SELECT ph.PostId,
           MAX(ph.CreationDate) AS LastClosedDate,
           STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasonNames
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS int)
    WHERE ph.PostHistoryTypeId = 10 -- Closed
    GROUP BY ph.PostId
),
QuestionActivity AS (
    SELECT p.Id AS QuestionId,
           p.Title,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           COALESCE(v.ScoreSum, 0) AS VoteScore,
           COALESCE(bp.BadgeCount, 0) AS UserBadgeCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN (
        SELECT postId, SUM(Score) AS ScoreSum 
        FROM Votes
        GROUP BY postId
    ) v ON v.postId = p.Id
    LEFT JOIN UserBadges bp ON bp.UserId = p.OwnerUserId
    WHERE p.PostTypeId = 1 -- Only Questions
),
FinalResults AS (
    SELECT qa.QuestionId,
           qa.Title,
           qa.CommentCount,
           qa.VoteScore,
           ua.DisplayName,
           ua.Reputation,
           ua.ReputationCategory,
           COALESCE(cp.LastClosedDate, 'Never Closed') AS LastClosed,
           COALESCE(cp.CloseReasonNames, 'N/A') AS CloseReasons
    FROM QuestionActivity qa
    JOIN ActiveUsers ua ON ua.Id = qa.OwnerUserId
    LEFT JOIN ClosedPosts cp ON cp.PostId = qa.QuestionId
    WHERE (qa.VoteScore < 0 OR qa.CommentCount > 0)
      AND ua.ReputationCategory = 'High Reputation'
)
SELECT f.QuestionId,
       f.Title,
       f.CommentCount,
       f.VoteScore,
       f.DisplayName,
       f.Reputation,
       f.ReputationCategory,
       f.LastClosed,
       f.CloseReasons
FROM FinalResults f
ORDER BY f.VoteScore DESC, f.CommentCount DESC
LIMIT 10;

-- Explain the final result:
-- This query retrieves the top 10 questions from high-reputation users
-- that have either negative vote scores or have received comments, 
-- along with details about their closing statuses and user badges.

WITH RecentQuestions AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.AnswerCount, p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn
    FROM Posts p
    WHERE p.PostTypeId = 1
      AND p.CreationDate >= NOW() - INTERVAL '30 days'
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation,
           RANK() OVER (ORDER BY u.Reputation DESC) as user_rank
    FROM Users u
    WHERE u.Reputation > 1000
),
QuestionStats AS (
    SELECT q.Id, q.Title, q.CreationDate, q.Score, q.AnswerCount, q.ViewCount,
           COALESCE((SELECT COUNT(c.Id) 
                     FROM Comments c 
                     WHERE c.PostId = q.Id), 0) AS CommentCount,
           CASE 
               WHEN q.Score > 10 THEN 'High Score'
               WHEN q.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
               ELSE 'Low Score'
           END AS ScoreCategory
    FROM RecentQuestions q
)
SELECT u.DisplayName, qs.Title, qs.CreationDate, qs.Score, qs.AnswerCount, 
       qs.ViewCount, qs.CommentCount, qs.ScoreCategory
FROM TopUsers u
JOIN QuestionStats qs ON u.Id = qs.OwnerUserId
WHERE u.user_rank <= 10
  AND qs.CreationDate < NOW() - INTERVAL '15 days'
ORDER BY qs.CreationDate DESC
LIMIT 20
UNION ALL
SELECT 'Community Post' AS DisplayName, 
       p.Title, p.CreationDate, p.Score, p.AnswerCount,
       p.ViewCount, COUNT(c.Id) AS CommentCount, 'Community Contribution' AS ScoreCategory
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.OwnerUserId = -1 
GROUP BY p.Id
HAVING COUNT(c.Id) > 5
ORDER BY p.CreationDate DESC
LIMIT 5


WITH RECURSIVE PostAnswers AS (
    SELECT p.Id AS PostId, p.AcceptedAnswerId, p.OwnerUserId, 
           p.CreationDate, p.Title, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1
    UNION ALL
    SELECT p.Id, p.AcceptedAnswerId, p.OwnerUserId, 
           p.CreationDate, p.Title, Level + 1
    FROM Posts p
    INNER JOIN PostAnswers pa ON p.ParentId = pa.PostId
    WHERE p.PostTypeId = 2
),
UserStats AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           u.Reputation, 
           u.CreationDate,
           COALESCE(COUNT(DISTINCT b.Id), 0) AS BadgeCount,
           SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId 
    GROUP BY u.Id
),
PostDetails AS (
    SELECT p.Id, p.Title, p.ViewCount, p.Score, 
           COUNT(DISTINCT c.Id) AS CommentCount,
           COUNT(DISTINCT pa.PostId) AS AnswerCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostAnswers pa ON p.Id = pa.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
)
SELECT us.UserId, us.DisplayName, us.Reputation, us.BadgeCount, us.TotalBounties,
       pd.Title, pd.ViewCount, pd.Score, pd.CommentCount, pd.AnswerCount,
       ROW_NUMBER() OVER (PARTITION BY us.UserId ORDER BY pd.Score DESC) AS Rank
FROM UserStats us
JOIN PostDetails pd ON us.UserId = pd.OwnerUserId
WHERE us.Reputation > 1000 
AND us.CreationDate < NOW() - INTERVAL '1 year'
ORDER BY us.Reputation DESC, pd.Score DESC
LIMIT 10;

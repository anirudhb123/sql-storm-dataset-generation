WITH UserStats AS (
  SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    AVG(pl.CreationDate - u.CreationDate) AS AvgTimeToPost
  FROM Users u
  LEFT JOIN Posts p ON u.Id = p.OwnerUserId
  LEFT JOIN Votes v ON p.Id = v.PostId
  LEFT JOIN PostLinks pl ON p.Id = pl.PostId
  GROUP BY u.Id, u.DisplayName, u.Reputation
),
BadgeCounts AS (
  SELECT 
    UserId,
    COUNT(*) AS BadgeCount
  FROM Badges
  GROUP BY UserId
),
TopUsers AS (
  SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpVotes,
    us.DownVotes,
    us.AvgTimeToPost,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount
  FROM UserStats us
  LEFT JOIN BadgeCounts bc ON us.UserId = bc.UserId
)
SELECT 
  DisplayName,
  Reputation,
  PostCount,
  QuestionCount,
  AnswerCount,
  UpVotes,
  DownVotes,
  BadgeCount,
  RANK() OVER (ORDER BY Reputation DESC, PostCount DESC, UpVotes DESC) AS Rank
FROM TopUsers
WHERE Reputation > 1000
ORDER BY Rank
LIMIT 50;

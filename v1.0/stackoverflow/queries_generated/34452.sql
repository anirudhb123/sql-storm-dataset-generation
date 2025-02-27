WITH RecursivePosts AS (
    SELECT Id, PostTypeId, Title, OwnerUserId, AcceptedAnswerId, CreationDate,
           ROW_NUMBER() OVER(PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS PostRank
    FROM Posts
    WHERE CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
           COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           COUNT(DISTINCT v.Id) AS VoteCount,
           AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 100
    GROUP BY u.Id
),
TopUsers AS (
    SELECT UserId, DisplayName, QuestionCount, AnswerCount, BadgeCount, VoteCount, AvgReputation,
           RANK() OVER (ORDER BY QuestionCount DESC, AnswerCount DESC) AS Rank
    FROM UserStats
)
SELECT t.Users.UserId, t.Users.DisplayName, t.Questions, t.Answers, t.Badges, t.Votes, t.Rank,
       COALESCE((
           SELECT COUNT(*)
           FROM Comments c
           WHERE c.UserId = t.Users.UserId AND c.CreationDate >= NOW() - INTERVAL '1 year'
       ), 0) AS RecentCommentCount,
       (SELECT STRING_AGG(DISTINCT pt.Name, ', ')
        FROM Posts p
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
        WHERE p.OwnerUserId = t.Users.UserId AND p.CreationDate >= NOW() - INTERVAL '1 year') AS PostTypesUsed
FROM (
    SELECT UserId, DisplayName, QuestionCount, AnswerCount, BadgeCount, VoteCount,
           CASE WHEN BadgeCount > 0 THEN '' || BadgeCount ELSE 'No Badges' END AS Badges,
           CASE WHEN VoteCount > 0 THEN '' || VoteCount ELSE 'No Votes' END AS Votes
    FROM TopUsers
    WHERE Rank <= 10
) AS t
LEFT JOIN RecursivePosts rp ON rp.OwnerUserId = t.UserId
WHERE rp.PostRank = 1
ORDER BY t.Rank;


WITH RankedUsers AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           u.CreationDate,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users AS u
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation
    FROM RankedUsers
    WHERE Rank <= 10
),
PostStats AS (
    SELECT p.Id AS PostId,
           p.Title,
           COUNT(c.Id) AS CommentCount,
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COALESCE(NULLIF(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0), 0) AS AcceptedAnswers
    FROM Posts AS p
    LEFT JOIN Comments AS c ON p.Id = c.PostId
    LEFT JOIN Votes AS v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY p.Id, p.Title
),
UserPosts AS (
    SELECT u.UserId,
           u.DisplayName,
           COUNT(p.Id) AS PostCount,
           COALESCE(SUM(ps.CommentCount), 0) AS TotalComments,
           COALESCE(SUM(ps.UpVotes), 0) AS TotalUpVotes,
           COALESCE(SUM(ps.DownVotes), 0) AS TotalDownVotes,
           COALESCE(SUM(ps.AcceptedAnswers), 0) AS TotalAcceptedAnswers
    FROM TopUsers AS u
    LEFT JOIN Posts AS p ON u.UserId = p.OwnerUserId
    LEFT JOIN PostStats AS ps ON p.Id = ps.PostId
    GROUP BY u.UserId, u.DisplayName
)
SELECT u.DisplayName,
       u.PostCount,
       u.TotalComments,
       u.TotalUpVotes,
       u.TotalDownVotes,
       u.TotalAcceptedAnswers
FROM UserPosts AS u
ORDER BY u.PostCount DESC, u.TotalUpVotes DESC;

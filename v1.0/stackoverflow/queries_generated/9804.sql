WITH UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(p.Id) AS PostCount, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
           SUM(v.VoteTypeId = 2) AS UpVotes, 
           SUM(v.VoteTypeId = 3) AS DownVotes, 
           AVG(Ex.PViewCount) AS AverageViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (SELECT PostId, SUM(ViewCount) AS PViewCount 
               FROM Posts 
               GROUP BY PostId) Ex ON p.Id = Ex.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, PostCount, QuestionCount, AnswerCount, UpVotes, DownVotes, AverageViewCount,
           RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
           RANK() OVER (ORDER BY UpVotes DESC) AS UpVoteRank
    FROM UserActivity
)
SELECT UserId, DisplayName, PostCount, QuestionCount, AnswerCount, UpVotes, DownVotes, AverageViewCount,
       PostRank, UpVoteRank
FROM TopUsers
WHERE PostRank <= 10 OR UpVoteRank <= 10
ORDER BY PostRank, UpVoteRank;

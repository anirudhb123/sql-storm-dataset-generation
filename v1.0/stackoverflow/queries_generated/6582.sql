WITH UserReputation AS (
    SELECT Id AS UserId, Reputation, CreationDate, DisplayName, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
    WHERE Reputation > 0
), PostStats AS (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts, 
           SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           SUM(ViewCount) AS TotalViews, SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
), UserPostPerformance AS (
    SELECT u.UserId, u.DisplayName, u.Reputation, 
           ps.TotalPosts, ps.Questions, ps.Answers,
           ps.TotalViews, ps.TotalScore,
           ur.ReputationRank
    FROM PostStats ps
    JOIN Users u ON u.Id = ps.OwnerUserId
    JOIN UserReputation ur ON u.Id = ur.UserId
), TopUsers AS (
    SELECT UserId, DisplayName, Reputation, TotalPosts, Questions, Answers, 
           TotalViews, TotalScore
    FROM UserPostPerformance
    WHERE ReputationRank <= 10
)
SELECT t.UserId, t.DisplayName, t.Reputation, t.TotalPosts, 
       t.Questions, t.Answers, t.TotalViews, t.TotalScore,
       (SELECT COUNT(*) FROM Votes v WHERE v.UserId = t.UserId) AS TotalVotes,
       (SELECT COUNT(DISTINCT b.Id) FROM Badges b WHERE b.UserId = t.UserId) AS TotalBadges
FROM TopUsers t
ORDER BY t.TotalScore DESC, t.TotalPosts DESC;

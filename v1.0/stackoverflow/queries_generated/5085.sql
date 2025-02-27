WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, LastAccessDate,
           RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
), 
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate
    FROM UserReputation u
    WHERE u.Rank <= 10
),
PostsWithScores AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
TopPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName AS OwnerDisplayName
    FROM PostsWithScores p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.UserPostRank <= 5
),
PostStats AS (
    SELECT tp.OwnerDisplayName, COUNT(tp.Id) AS TotalQuestions,
           SUM(tp.Score) AS TotalScore, SUM(tp.ViewCount) AS TotalViews
    FROM TopPosts tp
    GROUP BY tp.OwnerDisplayName
)
SELECT u.DisplayName, u.Reputation, ps.TotalQuestions, ps.TotalScore, ps.TotalViews
FROM TopUsers u
JOIN PostStats ps ON u.DisplayName = ps.OwnerDisplayName
ORDER BY u.Reputation DESC, ps.TotalScore DESC;

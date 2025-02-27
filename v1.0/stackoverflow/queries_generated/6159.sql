WITH UserReputation AS (
    SELECT Id, Reputation, DisplayName, CreationDate,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
           DENSE_RANK() OVER (PARTITION BY YEAR(CreationDate), MONTH(CreationDate) ORDER BY Reputation DESC) AS MonthlyReputationRank
    FROM Users
),
TopPosters AS (
    SELECT OwnerUserId, COUNT(Id) AS PostCount
    FROM Posts
    WHERE CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY OwnerUserId
    HAVING COUNT(Id) > 10
),
PopularTags AS (
    SELECT Tags.TagName, COUNT(Posts.Id) AS PostCount
    FROM Tags
    JOIN Posts ON Posts.Tags LIKE CONCAT('%', Tags.TagName, '%')
    GROUP BY Tags.TagName
    ORDER BY PostCount DESC
    LIMIT 5
),
PostActivity AS (
    SELECT P.Id AS PostId, P.Title, SUM(CASE WHEN H.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseOpenCount,
           AVG(VoteCount.VoteCount) AS AverageVotes, COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount
    FROM Posts P
    LEFT JOIN PostHistory H ON H.PostId = P.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) AS VoteCount ON VoteCount.PostId = P.Id
    LEFT JOIN Comments C ON C.PostId = P.Id
    GROUP BY P.Id, P.Title
),
FinalReport AS (
    SELECT U.DisplayName, U.Reputation, U.ReputationRank, U.MonthlyReputationRank, T.PostCount, 
           P.Title, P.CloseOpenCount, P.AverageVotes, P.CommentCount
    FROM UserReputation U
    JOIN TopPosters T ON T.OwnerUserId = U.Id
    JOIN PostActivity P ON P.PostId = (SELECT TOP 1 Id FROM Posts WHERE OwnerUserId = U.Id ORDER BY Score DESC)
    WHERE U.ReputationRank <= 100
)
SELECT FR.DisplayName, FR.Reputation, FR.ReputationRank, FR.MonthlyReputationRank, 
       FR.PostCount, FR.Title, FR.CloseOpenCount, FR.AverageVotes, FR.CommentCount, 
       PT.TagName AS PopularTag
FROM FinalReport FR
LEFT JOIN PopularTags PT ON PT.PostCount > 10
ORDER BY FR.Reputation DESC, FR.PostCount DESC;

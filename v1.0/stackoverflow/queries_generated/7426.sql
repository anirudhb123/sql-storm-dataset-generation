WITH UserReputation AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation, 
           RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
TopTags AS (
    SELECT T.Id AS TagId, 
           T.TagName, 
           COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.Id, T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
UserPostStats AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COUNT(P.Id) AS PostCount,
           SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
TopContributors AS (
    SELECT UPS.UserId,
           UPS.DisplayName,
           UPS.PostCount,
           UPS.TotalBounty,
           TPT.ReputationRank,
           ROW_NUMBER() OVER (ORDER BY UPS.PostCount DESC) AS ContributorRank
    FROM UserPostStats UPS
    JOIN UserReputation TPT ON UPS.UserId = TPT.UserId
),
PostDetails AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           P.CreationDate, 
           P.Score, 
           P.ViewCount, 
           P.AnswerCount, 
           P.CommentCount,
           T.TagName,
           U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN Users U ON P.OwnerUserId = U.Id
)
SELECT C.ContributorRank, 
       C.DisplayName AS ContributorName, 
       C.PostCount, 
       C.TotalBounty, 
       T.TagName AS TopTag, 
       D.*
FROM TopContributors C
JOIN TopTags T ON C.PostCount > 0
JOIN PostDetails D ON D.OwnerDisplayName = C.DisplayName
WHERE C.TotalBounty > 0
ORDER BY C.ContributorRank, D.CreationDate DESC
LIMIT 50;

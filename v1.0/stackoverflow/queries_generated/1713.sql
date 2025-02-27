WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(PS.TotalPosts, 0) DESC, COALESCE(UB.BadgeCount, 0) DESC) AS Rank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.Questions,
    T.Answers,
    T.AvgScore,
    T.BadgeCount,
    T.Rank
FROM TopUsers T
WHERE T.Rank <= 10
ORDER BY T.Rank;

SELECT 
    A.OwnerDisplayName,
    COUNT(C.Id) AS CommentCount,
    SUM(CASE WHEN C.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments
FROM Posts A
LEFT JOIN Comments C ON A.Id = C.PostId
WHERE A.LastActivityDate >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY A.OwnerDisplayName
HAVING COUNT(C.Id) > 0
ORDER BY PositiveComments DESC
LIMIT 5;

SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS PostCount,
    AVG(P.ViewCount) AS AvgViews,
    SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
FROM Posts P
JOIN PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN Votes V ON P.Id = V.PostId
WHERE PT.Name IS NOT NULL
GROUP BY PT.Name
ORDER BY PostCount DESC;

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(BA.BadgeCount, 0) AS BadgeCount 
FROM Users U
LEFT JOIN (
    SELECT UserId, COUNT(*) AS BadgeCount 
    FROM Badges 
    GROUP BY UserId
) BA ON U.Id = BA.UserId
WHERE U.Reputation IS NOT NULL AND U.Location IS NULL
ORDER BY U.Reputation DESC
LIMIT 10;

SELECT 
    COUNT(DISTINCT P.Id) AS UniqueQuestions,
    AVG(P.Score) AS AvgQuestionScore,
    MIN(P.CreationDate) AS EarliestCreation,
    MAX(P.CreationDate) AS LatestCreation
FROM Posts P
WHERE P.PostTypeId = 1 
  AND P.ClosedDate IS NULL
  AND P.LastActivityDate IS NOT NULL
  AND P.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE PostTypeId = 1)
  AND EXISTS (
      SELECT 1 
      FROM Comments C 
      WHERE C.PostId = P.Id AND C.CreationDate > CURRENT_DATE - INTERVAL '1 year'
  );

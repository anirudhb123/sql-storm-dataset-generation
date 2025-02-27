WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        AVG(CASE WHEN P.PostTypeId = 1 THEN P.Score END) AS AvgQuestionScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
BadgesByUser AS (
    SELECT 
        B.UserId, 
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
PostCommentStats AS (
    SELECT 
        PC.UserId,
        COUNT(PC.Id) AS TotalComments,
        AVG(PC.Score) AS AvgCommentScore
    FROM Comments PC
    GROUP BY PC.UserId
)
SELECT 
    US.DisplayName,
    US.Reputation,
    COALESCE(BU.BadgeCount, 0) AS BadgeCount,
    COALESCE(BU.GoldBadges, 0) AS GoldBadges,
    COALESCE(BU.SilverBadges, 0) AS SilverBadges,
    COALESCE(BU.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PCS.TotalComments, 0) AS TotalComments,
    COALESCE(PCS.AvgCommentScore, 0) AS AvgCommentScore,
    US.AvgQuestionScore,
    US.TotalAnswers,
    US.AcceptedQuestions
FROM UserStatistics US
LEFT JOIN BadgesByUser BU ON US.UserId = BU.UserId
LEFT JOIN PostCommentStats PCS ON US.UserId = PCS.UserId
WHERE US.Reputation > 1000
ORDER BY US.Reputation DESC, US.DisplayName ASC;

WITH RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    WHERE P.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    R.Id,
    R.Title,
    R.CreationDate,
    R.Score,
    U.DisplayName
FROM RecentPosts R
JOIN Users U ON R.OwnerUserId = U.Id
WHERE R.RN <= 3
ORDER BY R.CreationDate DESC;

SELECT 
    CASE 
        WHEN U.Reputation IS NOT NULL THEN U.DisplayName
        ELSE 'Unknown User'
    END AS UserName,
    COUNT(P.Id) AS PostCount,
    SUM(COALESCE(P.Score, 0)) AS TotalScore
FROM Users U
FULL OUTER JOIN Posts P ON U.Id = P.OwnerUserId
WHERE (U.Reputation IS NOT NULL OR P.Id IS NOT NULL)
GROUP BY UserName
HAVING SUM(COALESCE(P.Score, 0)) > 1000
ORDER BY TotalScore DESC;

SELECT 
    U.Id AS UserId,
    U.DisplayName AS UserName,
    COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
    COALESCE(SUM(V.CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes
FROM Users U
LEFT JOIN Votes V ON U.Id = V.UserId
GROUP BY U.Id, U.DisplayName
HAVING COALESCE(TotalBounties, 0) > 10
   OR COALESCE(TotalUpVotes, 0) > 50
ORDER BY UserName ASC;

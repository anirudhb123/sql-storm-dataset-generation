WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId OR C.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostTypeStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS NumberOfPosts,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews,
        MAX(P.CreationDate) AS MostRecentPostDate
    FROM PostTypes PT
    LEFT JOIN Posts P ON PT.Id = P.PostTypeId
    GROUP BY PT.Name
),
BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.TotalUpVotes,
    US.TotalDownVotes,
    COALESCE(BS.TotalBadges, 0) AS TotalBadges,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
    PTS.PostType,
    PTS.NumberOfPosts,
    PTS.TotalScore,
    PTS.AvgViews,
    PTS.MostRecentPostDate
FROM UserStats US
LEFT JOIN BadgeStats BS ON US.UserId = BS.UserId
LEFT JOIN PostTypeStats PTS ON US.TotalPosts >= 1
ORDER BY US.Reputation DESC, US.TotalPosts DESC, PTS.TotalScore DESC 
LIMIT 50;

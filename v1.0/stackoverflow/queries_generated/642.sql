WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        AcceptedAnswers,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
    WHERE Reputation > 5000
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(PL.RelatedPostId, -1) AS RelatedPostId,
        PT.Name AS PostType
    FROM Posts P
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        PostType,
        ROW_NUMBER() OVER (PARTITION BY PostType ORDER BY Score DESC) AS PostRank 
    FROM PostAnalytics
)
SELECT 
    H.UserId,
    H.DisplayName,
    H.Reputation,
    H.TotalPosts,
    H.TotalComments,
    H.AcceptedAnswers,
    H.GoldBadges,
    H.SilverBadges,
    H.BronzeBadges,
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViews
FROM HighReputationUsers H
LEFT JOIN TopPosts TP ON H.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId)
WHERE H.Rank <= 10
ORDER BY H.Reputation DESC, TP.Score DESC;

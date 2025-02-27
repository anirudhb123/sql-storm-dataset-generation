WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class AS BadgeClass
    FROM Users U
    JOIN Badges B ON U.Id = B.UserId
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(V.UPVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        COUNT(C.Id) AS CommentCount,
        COUNT(PH.Id) AS EditCount,
        COUNT(PL.Id) AS RelatedPostsCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.ViewCount, V.UPVotes, V.DownVotes
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY SUM(P.ViewCount) DESC) AS Rank
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE P.PostTypeId = 1 -- Only questions
    GROUP BY U.Id, U.DisplayName
),
BadgeDistribution AS (
    SELECT 
        BadgeName,
        COUNT(DISTINCT UserId) AS UserCount,
        SUM(CASE WHEN BadgeClass = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN BadgeClass = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN BadgeClass = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM UserBadges
    GROUP BY BadgeName
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalViews,
    T.TotalAnswers,
    COALESCE(B.UserCount, 0) AS UniqueBadgeHolders,
    COALESCE(B.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(B.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(B.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM TopUsers T
LEFT JOIN BadgeDistribution B ON 1=1 -- Join to include all badge distribution
WHERE T.Rank <= 10
ORDER BY T.TotalViews DESC;

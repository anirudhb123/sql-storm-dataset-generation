WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ActivityRank
    FROM UserActivity
    WHERE ActivityRank <= 10
)

SELECT 
    U.DisplayName,
    T.TotalPosts,
    T.TotalComments,
    T.TotalUpVotes,
    T.TotalDownVotes,
    (T.GoldBadges + T.SilverBadges + T.BronzeBadges) AS TotalBadges,
    CASE 
        WHEN T.GoldBadges > 0 THEN 'Gold Badge Holder'
        WHEN T.SilverBadges > 0 THEN 'Silver Badge Holder'
        WHEN T.BronzeBadges > 0 THEN 'Bronze Badge Holder'
        ELSE 'No Badge Holder' 
    END AS BadgeStatus
FROM TopUsers T
JOIN Users U ON T.UserId = U.Id
ORDER BY T.TotalPosts DESC, T.TotalComments DESC;

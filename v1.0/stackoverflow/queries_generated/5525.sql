WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000 
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalTagWikis, 
        TotalComments, 
        TotalBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM UserStats
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalTagWikis,
    U.TotalComments,
    U.TotalBadges,
    T.UserRank
FROM TopUsers T
JOIN Users U ON T.UserId = U.Id
WHERE T.UserRank <= 10
ORDER BY T.UserRank;

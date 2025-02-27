
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AvgPostScore,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AvgPostScore,
        TotalComments,
        @row_num := IF(@prev_reputation = Reputation, @row_num + 1, 1) AS PostRank,
        @prev_reputation := Reputation,
        @total_users := @total_users + 1 AS TotalUsers
    FROM UserPostStats, (SELECT @row_num := 0, @prev_reputation := NULL, @total_users := 0) r
    ORDER BY Reputation, TotalPosts DESC
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AvgPostScore,
        TotalComments
    FROM RankedUsers
    WHERE PostRank <= 10
)

SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.AvgPostScore,
    TC.CommentCount
FROM TopUsers TU
LEFT JOIN (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY P.OwnerUserId
) TC ON TU.UserId = TC.OwnerUserId
WHERE TU.TotalPosts > 5 
ORDER BY TU.Reputation DESC, TU.TotalPosts DESC;

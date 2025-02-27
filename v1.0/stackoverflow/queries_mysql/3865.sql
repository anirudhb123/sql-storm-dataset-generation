
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(C.CommentsCount, 0)) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentsCount
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
ActivityRanked AS (
    SELECT 
        UA.*,
        @row_number := @row_number + 1 AS ActivityRank
    FROM UserActivity UA, (SELECT @row_number := 0) AS rn
    ORDER BY UA.PostCount DESC, UA.TotalComments DESC
),
TopUsers AS (
    SELECT 
        U.*,
        CASE 
            WHEN U.Reputation < 100 THEN 'Newbie'
            WHEN U.Reputation < 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users U
    WHERE U.Id IN (SELECT UserId FROM ActivityRanked WHERE ActivityRank <= 10)
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.ReputationLevel,
    AR.QuestionCount,
    AR.AnswerCount,
    AR.TotalComments
FROM TopUsers TU
JOIN ActivityRanked AR ON TU.Id = AR.UserId
LEFT JOIN Badges B ON TU.Id = B.UserId AND B.Class = 1
WHERE B.Id IS NULL 
ORDER BY TU.Reputation DESC, AR.QuestionCount DESC;

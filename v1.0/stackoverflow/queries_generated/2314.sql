WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        AvgViewCount,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserPostStats
    WHERE PostCount > 5
),
PostCommentStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id
),
FrequentComments AS (
    SELECT 
        PostId,
        CommentCount,
        DENSE_RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank
    FROM PostCommentStats
)
SELECT 
    U.DisplayName AS UserName,
    T.QuestionCount,
    T.AnswerCount,
    COALESCE(C.CommentCount, 0) AS TotalComments,
    T.TotalScore,
    T.AvgViewCount
FROM TopUsers T
LEFT JOIN FrequentComments C ON T.UserId = C.PostId
WHERE T.ScoreRank <= 10 AND (C.CommentRank IS NULL OR C.CommentRank <= 5)
ORDER BY T.TotalScore DESC, T.AvgViewCount DESC;

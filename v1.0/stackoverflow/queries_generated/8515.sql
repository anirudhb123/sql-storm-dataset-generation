WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        AvgScore, 
        TotalViews,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM UserPostStats
),
TopViewedQuestions AS (
    SELECT 
        P.Id AS QuestionId, 
        P.Title AS QuestionTitle,
        P.ViewCount AS QuestionViews,
        C.UserDisplayName AS AnsweredBy,
        C.CreationDate AS AnswerDate
    FROM Posts P
    JOIN Posts PA ON P.Id = PA.AcceptedAnswerId
    JOIN Comments C ON PA.Id = C.PostId
    WHERE P.PostTypeId = 1
    AND PA.PostTypeId = 2
    ORDER BY P.ViewCount DESC
    LIMIT 5
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.AvgScore,
    U.TotalViews,
    Q.QuestionId,
    Q.QuestionTitle,
    Q.QuestionViews,
    Q.AnsweredBy,
    Q.AnswerDate
FROM TopUsers U
JOIN TopViewedQuestions Q ON U.UserId = Q.AnsweredBy
WHERE U.PostRank <= 10 OR U.ViewRank <= 10
ORDER BY U.TotalPosts DESC, U.TotalViews DESC;

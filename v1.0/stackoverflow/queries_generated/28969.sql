WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(P.Score) AS AverageScore
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LEFT JOIN Comments C ON C.PostId = P.Id
    WHERE P.PostTypeId = 1  -- Only considering Questions
    GROUP BY T.TagName
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes
    FROM Users U
    JOIN Posts P ON P.OwnerUserId = U.Id AND P.PostTypeId = 1
    LEFT JOIN Votes V ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
ClosedQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        PH.Comment AS CloseReason,
        U.DisplayName AS ClosedBy
    FROM Posts P
    JOIN PostHistory PH ON PH.PostId = P.Id AND PH.PostHistoryTypeId = 10  -- Post Closed
    LEFT JOIN Users U ON U.Id = PH.UserId
),
FinalReport AS (
    SELECT 
        TS.TagName,
        TS.PostCount,
        TS.TotalViews,
        TS.TotalComments,
        TS.AverageScore,
        TU.DisplayName AS TopUser,
        TU.QuestionsAsked,
        TU.AcceptedAnswers,
        TU.TotalUpVotes,
        CQ.ClosedDate,
        CQ.Title AS ClosedQuestionTitle,
        CQ.CloseReason,
        CQ.ClosedBy
    FROM TagStatistics TS
    LEFT JOIN TopUsers TU ON TU.QuestionsAsked = (
        SELECT MAX(QuestionsAsked) FROM TopUsers
    ) 
    LEFT JOIN ClosedQuestions CQ ON CQ.ClosedDate IS NOT NULL
    ORDER BY TS.PostCount DESC
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    TotalComments,
    AverageScore,
    TopUser,
    QuestionsAsked,
    AcceptedAnswers,
    TotalUpVotes,
    ClosedDate,
    ClosedQuestionTitle,
    CloseReason,
    ClosedBy
FROM FinalReport
WHERE PostCount > 0;  -- Only consider tags with associated questions

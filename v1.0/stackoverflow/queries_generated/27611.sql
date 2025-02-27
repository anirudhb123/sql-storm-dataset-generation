WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN V.Id END) AS TotalUpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN V.Id END) AS TotalDownVotes
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        T.TagName
),
MostActiveUsers AS (
    SELECT 
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided,
        SUM(V.CreationDate IS NOT NULL) AS VotesGiven
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.DisplayName
    ORDER BY 
        QuestionsAsked DESC, AnswersProvided DESC
    LIMIT 10
),
CloseReasonCounts AS (
    SELECT 
        CH.Comment AS CloseReason,
        COUNT(CH.Id) AS CloseCount
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CH ON PH.Comment = CAST(CH.Id AS VARCHAR)
    WHERE 
        PH.PostHistoryTypeId IN (10, 12) -- closed or deleted
    GROUP BY 
        CH.Comment
),
TopTags AS (
    SELECT 
        TagName,
        PostCount
    FROM 
        TagStatistics
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    T.TagName AS TopTag,
    T.PostCount AS TotalPosts,
    T.QuestionCount AS TotalQuestions,
    T.AnswerCount AS TotalAnswers,
    T.TotalUpVotes,
    T.TotalDownVotes,
    U.DisplayName AS MostActiveUser,
    U.QuestionsAsked,
    U.AnswersProvided,
    U.VotesGiven,
    C.CloseReason,
    C.CloseCount
FROM 
    TagStatistics T
CROSS JOIN 
    MostActiveUsers U
CROSS JOIN 
    CloseReasonCounts C
WHERE 
    T.TagName IN (SELECT TagName FROM TopTags) 
ORDER BY 
    T.PostCount DESC, U.QuestionsAsked DESC;

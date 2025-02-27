WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS Comments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ActivityRanked AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Questions,
        Answers,
        AcceptedAnswers,
        Comments,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY Questions DESC) AS QuestionRank,
        RANK() OVER (ORDER BY Answers DESC) AS AnswerRank
    FROM 
        UserActivity
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Questions,
        Answers,
        AcceptedAnswers,
        Comments,
        PostRank,
        QuestionRank,
        AnswerRank
    FROM 
        ActivityRanked
    WHERE 
        PostRank <= 10 OR QuestionRank <= 10 OR AnswerRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.Questions,
    TU.Answers,
    TU.AcceptedAnswers,
    TU.Comments,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed,
    COUNT(DISTINCT C.Id) AS TotalComments,
    COUNT(DISTINCT PH.Id) AS PostHistoryCount
FROM 
    TopUsers TU
LEFT JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
LEFT JOIN 
    STRING_TO_ARRAY(P.Tags, ',') AS T ON true
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
GROUP BY 
    TU.UserId, TU.DisplayName, TU.Reputation, TU.PostCount, TU.Questions, TU.Answers, TU.AcceptedAnswers, TU.Comments
ORDER BY 
    TU.Reputation DESC;

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(V.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Views
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        Views,
        PostsCount,
        QuestionsCount,
        AnswersCount,
        TotalBounty,
        Rank
    FROM UserActivity
    WHERE Rank <= 10
),
QuestionStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalQuestions,
        AVG(P.Score) AS AvgQuestionScore,
        SUM(P.ViewCount) AS TotalViews,
        (SELECT COUNT(*) FROM Posts PA WHERE PA.ParentId = P.Id) AS AnswerCount
    FROM Posts P
    WHERE P.PostTypeId = 1
    GROUP BY P.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.Views,
    U.PostsCount,
    U.QuestionsCount,
    U.AnswersCount,
    U.TotalBounty,
    Q.TotalQuestions,
    Q.AvgQuestionScore,
    Q.TotalViews,
    Q.AnswerCount
FROM TopUsers U
LEFT JOIN QuestionStats Q ON U.UserId = Q.OwnerUserId
ORDER BY U.Reputation DESC;

-- This query retrieves the top 10 users by reputation who have more than 1000 reputation points.
-- It includes their activity metrics such as the number of posts, questions, and answers, along with the total bounty they received.
-- It also computes additional statistics about the questions they have asked including average score and total views.
-- A CTE is used to calculate user activity, and another CTE is used to gather statistics specific to questions.
-- The results are ordered by the users' reputations in descending order. 

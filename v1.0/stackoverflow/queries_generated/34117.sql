WITH RecursivePostTree AS (
    -- Recursive CTE to get all answers for questions in a specific time frame
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        0 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1 AND P.CreationDate >= '2023-01-01'  -- Questions after January 1, 2023

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        R.Level + 1
    FROM Posts P
    INNER JOIN Posts Q ON P.ParentId = Q.Id
    INNER JOIN RecursivePostTree R ON R.PostId = Q.Id  -- Join to get answers to previous questions
)

SELECT 
    U.DisplayName AS User,
    U.Reputation,
    COUNT(DISTINCT Q.Id) AS TotalQuestions,
    COUNT(DISTINCT A.PostId) AS TotalAnswers,
    AVG(A.Score) AS AverageAnswerScore,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed,
    COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
FROM Users U
LEFT JOIN Posts Q ON U.Id = Q.OwnerUserId AND Q.PostTypeId = 1  -- Questions
LEFT JOIN RecursivePostTree A ON A.PostId = Q.AcceptedAnswerId  -- Accepted answers linked to questions
LEFT JOIN PostLinks PL ON PL.PostId = Q.Id
LEFT JOIN Tags T ON T.Id = PL.RelatedPostId
LEFT JOIN Votes V ON V.PostId = Q.Id AND V.VoteTypeId = 8  -- Bounty votes
WHERE U.Reputation > 100  -- Filtering users with reputation greater than 100
GROUP BY U.Id, U.DisplayName, U.Reputation
HAVING COUNT(DISTINCT Q.Id) > 0  -- Only include users with questions
ORDER BY TotalQuestions DESC, AverageAnswerScore DESC;

-- The above query does the following:
-- 1. Retrieves users with a reputation greater than 100 who have asked questions since January 1, 2023.
-- 2. Calculates the total number of questions and average score of accepted answers.
-- 3. Aggregates tags from linked questions.
-- 4. Sums up any bounties that have been given to their questions.

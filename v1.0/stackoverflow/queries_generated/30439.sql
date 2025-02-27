WITH RecursivePostCTE AS (
    -- Recursive CTE to get the hierarchy of parents for answers followed by their counts
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        1 AS Depth
    FROM Posts P
    WHERE P.PostTypeId = 2  -- Start from Answers

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        RPC.Depth + 1
    FROM Posts P
    INNER JOIN RecursivePostCTE RPC ON P.Id = RPC.ParentId
),
PostScoreCTE AS (
    -- CTE to calculate the average score for questions and total answers
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        AVG(A.Score) AS AvgAnswerScore,
        COUNT(A.Id) AS TotalAnswers
    FROM Posts P
    LEFT JOIN Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2  -- Left join to Answers
    WHERE P.PostTypeId = 1  -- Only Questions
    GROUP BY P.Id
),
UserBadgesCTE AS (
    -- CTE to get badge details for users who have answered the questions
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    JOIN Posts A ON U.Id = A.OwnerUserId AND A.PostTypeId = 2  -- Answers
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    P.Title AS QuestionTitle,
    PS.TotalAnswers,
    PS.AvgAnswerScore,
    U.DisplayName AS AnswererDisplayName,
    U.BadgeCount,
    COUNT(DISTINCT C.Id) AS CommentCount,
    MAX(C.CreationDate) AS LastCommentDate,
    STRING_AGG(T.TagName, ', ') AS Tags,
    CASE
        WHEN PS.AvgAnswerScore IS NULL THEN 'No Answers'
        WHEN PS.AvgAnswerScore > 5 THEN 'Good Answer Quality'
        ELSE 'Needs Improvement'
    END AS AnswerQualityFeedback,
    CASE 
        WHEN PS.TotalAnswers > 10 THEN 'High Activity'
        WHEN PS.TotalAnswers BETWEEN 5 AND 10 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM Posts P
JOIN PostScoreCTE PS ON P.Id = PS.QuestionId
JOIN UserBadgesCTE U ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = P.Id)
LEFT JOIN Comments C ON C.PostId = P.Id
LEFT JOIN LATERAL (
    SELECT 
        T.TagName
    FROM Tags T
    WHERE T.Id IN (SELECT UNNEST(string_to_array(P.Tags, '<>'))::int)  -- Assuming tags are formatted with <tag1><tag2>
) T ON true  -- Cross join for tags
WHERE P.PostTypeId = 1  -- Filter only questions
GROUP BY 
    P.Title, 
    PS.TotalAnswers, 
    PS.AvgAnswerScore, 
    U.DisplayName, 
    U.BadgeCount
HAVING 
    COUNT(DISTINCT C.Id) > 0  -- Only questions with comments
ORDER BY 
    PS.AvgAnswerScore DESC, 
    PS.TotalAnswers DESC;

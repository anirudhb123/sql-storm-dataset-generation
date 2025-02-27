WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        P.AcceptedAnswerId,
        CAST(NULL AS varchar(300)) AS AcceptedAnswerTitle,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        P.Id,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        P.AcceptedAnswerId,
        PA.Title AS AcceptedAnswerTitle,
        Level + 1
    FROM 
        Posts P
    JOIN 
        Posts PA ON P.AcceptedAnswerId = PA.Id
    WHERE 
        P.PostTypeId = 1
)

SELECT 
    U.DisplayName AS UserName,
    COUNT(DISTINCT P.Id) AS TotalQuestions,
    SUM(P.Score) AS TotalScore,
    SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
    SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount,
    MAX(RPS.CreationDate) AS LatestPostDate,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    AVG(VotesCount) AS AvgVotes
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    PostLinks PL ON P.Id = PL.PostId
LEFT JOIN 
    Tags T ON T.ExcerptPostId = P.Id
LEFT JOIN 
    (
        SELECT 
            PostId, 
            COUNT(*) as VotesCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS V ON V.PostId = P.Id
LEFT JOIN 
    RecursivePostStats RPS ON P.Id = RPS.PostId
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.DisplayName
HAVING 
    COUNT(DISTINCT P.Id) > 5
ORDER BY 
    TotalScore DESC;

This query uses a recursive CTE (`RecursivePostStats`) to gather data on accepted answers for questions, alongside aggregation of questions and various historical states from `PostHistory`. It employs string aggregation for tags, conditional counting, and also includes filtering for users with a reputation above 1000 and groups by user display names to calculate total scores and activity metrics. Furthermore, it showcases the use of left joins and aggregate functions to provide a comprehensive overview of user activity within the Stack Overflow schema, making it optimal for performance benchmarking and insightful analysis.

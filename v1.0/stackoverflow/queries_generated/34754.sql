WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.ParentId,
        PH.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy PH ON P.ParentId = PH.PostId
)

SELECT 
    U.DisplayName AS UserDisplayName,
    COUNT(DISTINCT Q.PostId) AS TotalQuestions,
    COUNT(DISTINCT A.PostId) AS TotalAnswers,
    COUNT(PHT.Id) AS TotalPostHistoryRecords,
    SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
    MAX(Q.CreationDate) AS LatestQuestionDate,
    MIN(A.CreationDate) AS EarliestAnswerDate
FROM 
    Users U
LEFT JOIN 
    Posts Q ON U.Id = Q.OwnerUserId AND Q.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts A ON U.Id = A.OwnerUserId AND A.PostTypeId = 2 -- Answers
LEFT JOIN 
    PostHistory PHT ON Q.Id = PHT.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.Reputation > 1000 -- Only users with reputation greater than 1000
GROUP BY 
    U.DisplayName
HAVING 
    COUNT(DISTINCT Q.PostId) > 0 AND 
    COUNT(DISTINCT A.PostId) > 0
ORDER BY 
    TotalAnswers DESC, 
    U.DisplayName ASC;

-- To include related posts information
SELECT 
    RPH.PostId,
    RPH.Title,
    RPH.OwnerUserId,
    RPH.CreationDate,
    RPH.Level,
    PT.Name AS PostType
FROM 
    RecursivePostHierarchy RPH
LEFT JOIN 
    PostTypes PT ON (SELECT PostTypeId FROM Posts WHERE Id = RPH.PostId) = PT.Id
WHERE 
    RPH.Level <= 3 -- Limit to 3 levels of hierarchy
ORDER BY 
    RPH.Level, 
    RPH.CreationDate DESC;

This query performs the following:
- It constructs a recursive Common Table Expression (CTE) to get the hierarchy of posts, allowing us to see the structure of questions and answers over several levels.
- It retrieves user data focusing on users with a reputation greater than 1000, counting the number of questions and answers they have posted, as well as the associated badge awards.
- The main query aggregates these counts and includes having clauses to ensure results only display users who have created both questions and answers.
- Afterward, it fetches details from the recursive post hierarchy including post types, providing a clear view of how posts are interconnected through their parent-child relationships.

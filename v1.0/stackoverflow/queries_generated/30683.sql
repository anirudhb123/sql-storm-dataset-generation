WITH RecursivePostHierarchy AS (
    -- CTE to create a hierarchy of posts and their accepted answers or parent questions
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.AcceptedAnswerId,
        P.Title,
        0 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Selecting only questions

    UNION ALL

    SELECT 
        P.Id,
        P.ParentId,
        P.AcceptedAnswerId,
        P.Title,
        Level + 1
    FROM Posts P
    INNER JOIN RecursivePostHierarchy R ON P.Id = R.AcceptedAnswerId
)

-- Main query to benchmark performance with multiple joins, aggregations, and window functions
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS QuestionCount,
    SUM(COALESCE(P.Score, 0)) AS TotalScore,
    AVG(COALESCE(P.ViewCount, 0)) AS AverageViews,
    STRING_AGG(DISTINCT TG.TagName, ', ') AS TagsUsed,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS Rank,
    (SELECT COUNT(*)
     FROM Votes V
     WHERE V.UserId = U.Id AND V.VoteTypeId = 2) AS UpvotesGiven,
    (SELECT COUNT(*)
     FROM Badges B
     WHERE B.UserId = U.Id) AS TotalBadges,
    CASE 
        WHEN COUNT(DISTINCT P.Id) > 50 THEN 'Expert'
        WHEN COUNT(DISTINCT P.Id) BETWEEN 10 AND 50 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  -- Questions
LEFT JOIN Tags TG ON P.Tags LIKE '%' || TG.TagName || '%'  -- Joining on tags
LEFT JOIN RecursivePostHierarchy R ON P.Id = R.PostId  -- Joining with recursive CTE for accepted answers
WHERE U.Reputation > 10  -- Filter users based on reputation

GROUP BY U.Id, U.DisplayName
HAVING COUNT(DISTINCT P.Id) > 5  -- Only users with more than 5 questions
ORDER BY TotalScore DESC, QuestionCount DESC;

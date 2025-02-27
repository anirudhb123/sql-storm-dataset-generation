-- Performance benchmarking SQL query for the Stack Overflow schema

-- This query retrieves the top 10 most active users based on the number of posts they have created
-- and the total score of those posts, along with their reputation and display name.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS PostCount,
    SUM(P.Score) AS TotalScore
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    PostCount DESC, TotalScore DESC
LIMIT 10;

-- This query benchmarks the average score of questions by tag
-- It retrieves the average score of questions grouped by tags.

SELECT 
    TRIM(UNNEST(STRING_TO_ARRAY(P.Tags, '>'))::text) AS Tag,
    AVG(P.Score) AS AverageScore
FROM 
    Posts P
WHERE 
    P.PostTypeId = 1  -- Only questions
GROUP BY 
    Tag
ORDER BY 
    AverageScore DESC
LIMIT 10;

-- This query assesses the average time taken to receive an accepted answer
-- It calculates the time difference between question creation and accepted answer date.

SELECT 
    P.Id AS QuestionId,
    P.Title,
    AVG(EXTRACT(EPOCH FROM (A.CreationDate - P.CreationDate)) / 3600) AS AverageHoursToAccept
FROM 
    Posts P
JOIN 
    Posts A ON P.Id = A.AcceptedAnswerId
WHERE 
    P.PostTypeId = 1 AND A.PostTypeId = 2  -- Questions and their accepted answers
GROUP BY 
    P.Id, P.Title
ORDER BY 
    AverageHoursToAccept ASC
LIMIT 10;

-- This query retrieves the most common close reasons used
SELECT 
    C.R.CloseReasonId,
    COUNT(P.Id) AS CloseReasonCount
FROM 
    PostHistory PH
JOIN 
    CloseReasonTypes C ON PH.Comment::int = C.Id
JOIN 
    Posts P ON PH.PostId = P.Id
WHERE 
    PH.PostHistoryTypeId IN (10, 11)  -- Closed and reopened posts
GROUP BY 
    C.Id
ORDER BY 
    CloseReasonCount DESC
LIMIT 10;

-- This query gets the count of posts and their associated comments
SELECT 
    P.Id AS PostId,
    COUNT(COM.Id) AS CommentCount
FROM 
    Posts P
LEFT JOIN 
    Comments COM ON P.Id = COM.PostId
GROUP BY 
    P.Id
ORDER BY 
    CommentCount DESC
LIMIT 10;

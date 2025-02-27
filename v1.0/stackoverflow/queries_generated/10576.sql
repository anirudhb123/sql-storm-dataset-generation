-- Performance Benchmarking SQL Query

-- 1. Count the number of Posts grouped by PostTypeId to identify distribution
SELECT 
    PostTypeId,
    COUNT(*) AS PostCount
FROM 
    Posts
GROUP BY 
    PostTypeId
ORDER BY 
    PostCount DESC;

-- 2. Average Score of Posts by PostTypeId
SELECT 
    PostTypeId,
    AVG(Score) AS AverageScore
FROM 
    Posts
GROUP BY 
    PostTypeId
ORDER BY 
    AverageScore DESC;

-- 3. Top 10 Users by Reputation and their total number of Posts
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC
LIMIT 10;

-- 4. Total number of Comments on Posts
SELECT 
    P.Id AS PostId,
    COUNT(C.Id) AS CommentCount
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    P.Id
ORDER BY 
    CommentCount DESC;

-- 5. List PostHistory changes with type and count
SELECT 
    PHT.Name AS ChangeType,
    COUNT(PH.Id) AS ChangesCount
FROM 
    PostHistory PH
JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
GROUP BY 
    PHT.Name
ORDER BY 
    ChangesCount DESC;

-- 6. Average CreationDate difference in days between Posts and their accepted answers
SELECT 
    AVG(DATE_PART('day', PA.CreationDate - P.CreationDate)) AS AvgDaysToAcceptedAnswer
FROM 
    Posts P
LEFT JOIN 
    Posts PA ON P.Id = P.AcceptedAnswerId
WHERE 
    P.PostTypeId = 1  -- Only Questions
GROUP BY 
    P.Id;

-- 7. Total number of votes by VoteTypeId
SELECT 
    VT.Id AS VoteTypeId,
    VT.Name AS VoteType,
    COUNT(V.Id) AS VoteCount
FROM 
    VoteTypes VT
LEFT JOIN 
    Votes V ON VT.Id = V.VoteTypeId
GROUP BY 
    VT.Id, VT.Name
ORDER BY 
    VoteCount DESC;

-- 8. Average ViewCount of Posts with Closed status
SELECT 
    AVG(ViewCount) AS AvgClosedPostViews
FROM 
    Posts
WHERE 
    ClosedDate IS NOT NULL;

-- 9. User participation statistics: Reputation and Total Votes
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(V.Id) AS TotalVotes
FROM 
    Users U
LEFT JOIN 
    Votes V ON U.Id = V.UserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalVotes DESC;

-- 10. Monthly post creation trend
SELECT 
    DATE_TRUNC('month', CreationDate) AS Month,
    COUNT(*) AS PostCount
FROM 
    Posts
GROUP BY 
    Month
ORDER BY 
    Month;

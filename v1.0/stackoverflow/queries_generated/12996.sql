-- Performance benchmarking SQL query for the StackOverflow database schema

-- Query 1: Retrieve top 10 users with the highest reputation and their total number of posts
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

-- Query 2: Average score of questions and answers grouped by post type
SELECT 
    PT.Name AS PostTypeName,
    AVG(P.Score) AS AverageScore
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    PT.Name;

-- Query 3: Count of votes by type for posts
SELECT 
    VT.Name AS VoteTypeName,
    COUNT(V.Id) AS VoteCount
FROM 
    Votes V
JOIN 
    VoteTypes VT ON V.VoteTypeId = VT.Id
GROUP BY 
    VT.Name;

-- Query 4: Number of comments per post type
SELECT 
    PT.Name AS PostTypeName,
    COUNT(C.Id) AS CommentCount
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    PT.Name;

-- Query 5: Retrieve posts with the highest view count
SELECT 
    P.Title,
    P.ViewCount,
    U.DisplayName AS OwnerDisplayName
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
ORDER BY 
    P.ViewCount DESC
LIMIT 10;

-- Query 6: Count of badges received by users
SELECT 
    U.DisplayName,
    COUNT(B.Id) AS BadgeCount
FROM 
    Users U
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.DisplayName
ORDER BY 
    BadgeCount DESC
LIMIT 10;

-- Query 7: Total number of posts created each month
SELECT 
    DATE_TRUNC('month', P.CreationDate) AS Month,
    COUNT(P.Id) AS PostsCreated
FROM 
    Posts P
GROUP BY 
    Month
ORDER BY 
    Month;

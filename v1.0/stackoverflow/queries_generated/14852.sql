-- Performance Benchmarking Query

-- Measure the number of posts created by each user and their average score
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AverageScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    PostCount DESC;

-- Measure the distribution of badges across users
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(B.Id) AS BadgeCount
FROM 
    Users U
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    BadgeCount DESC;

-- Measure the number of comments on posts grouped by post type
SELECT 
    PT.Name AS PostType,
    COUNT(C.Id) AS CommentCount
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    PT.Name
ORDER BY 
    CommentCount DESC;

-- Measure the number of votes on posts by vote type
SELECT 
    VT.Name AS VoteType,
    COUNT(V.Id) AS VoteCount
FROM 
    Votes V
JOIN 
    VoteTypes VT ON V.VoteTypeId = VT.Id
GROUP BY 
    VT.Name
ORDER BY 
    VoteCount DESC;

-- Measure the average view count of questions over time
SELECT 
    DATE_TRUNC('month', P.CreationDate) AS Month,
    AVG(P.ViewCount) AS AverageViewCount
FROM 
    Posts P
WHERE 
    P.PostTypeId = 1
GROUP BY 
    Month
ORDER BY 
    Month;

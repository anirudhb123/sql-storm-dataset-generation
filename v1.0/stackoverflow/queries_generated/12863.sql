-- Performance benchmarking query for StackOverflow schema

-- Measure the number of posts, their types, and average scores
SELECT 
    P.PostTypeId,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AverageScore
FROM 
    Posts P
GROUP BY 
    P.PostTypeId
ORDER BY 
    P.PostTypeId;

-- Benchmarking the number of badges per user and the average reputation
SELECT 
    U.Id AS UserId,
    COUNT(B.Id) AS BadgeCount,
    AVG(U.Reputation) AS AverageReputation
FROM 
    Users U
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.Id
ORDER BY 
    BadgeCount DESC;

-- Query to evaluate the number of votes per post
SELECT 
    P.Id AS PostId,
    COUNT(V.Id) AS VoteCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts P
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id
ORDER BY 
    VoteCount DESC;

-- Performance metrics on the reaction time related to edits and closing posts
SELECT 
    PH.PostId,
    MIN(PH.CreationDate) AS FirstActionDate,
    MAX(PH.CreationDate) AS LastActionDate,
    COUNT(PH.Id) AS ActionCount,
    MAX(PH.CreationDate) - MIN(PH.CreationDate) AS Duration
FROM 
    PostHistory PH
WHERE 
    PH.PostHistoryTypeId IN (10, 11, 24) -- Closing, Reopening, Suggested Edit
GROUP BY 
    PH.PostId
ORDER BY 
    Duration DESC;

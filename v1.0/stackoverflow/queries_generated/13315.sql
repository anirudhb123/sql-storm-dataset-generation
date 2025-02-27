-- Performance Benchmarking Query for Stack Overflow Schema

-- Fetch top users by reputation with their post and vote details
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    COUNT(V.Id) AS TotalVotes,
    SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    VoteTypes VT ON V.VoteTypeId = VT.Id
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC
LIMIT 10;

-- Fetch post details with associated comments and edit history
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    COALESCE(COUNT(C.Id), 0) AS TotalComments,
    COALESCE(HT.EditCount, 0) AS TotalEdits
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT 
         PH.PostId, 
         COUNT(PH.Id) AS EditCount
     FROM 
         PostHistory PH
     WHERE 
         PH.PostHistoryTypeId IN (4, 5, 6)
     GROUP BY 
         PH.PostId) AS HT ON P.Id = HT.PostId
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts from the last year
GROUP BY 
    P.Id, HT.EditCount
ORDER BY 
    P.CreationDate DESC
LIMIT 20;

-- Fetch average views and score of questions over time
SELECT 
    DATE_TRUNC('month', P.CreationDate) AS Month,
    AVG(P.ViewCount) AS AvgViewCount,
    AVG(P.Score) AS AvgScore
FROM 
    Posts P
WHERE 
    P.PostTypeId = 1  -- Only questions
GROUP BY 
    Month
ORDER BY 
    Month DESC
LIMIT 12;


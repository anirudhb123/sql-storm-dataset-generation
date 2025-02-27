-- Performance benchmarking query for the StackOverflow schema

-- Retrieve the total count of different post types along with their average scores
SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;

-- Benchmark the average response time in terms of the time taken from question creation to first answer
SELECT 
    AVG(EXTRACT(EPOCH FROM (A.CreationDate - Q.CreationDate))) AS AverageResponseTimeSeconds,
    COUNT(A.Id) AS TotalResponses
FROM 
    Posts Q
JOIN 
    Posts A ON Q.Id = A.ParentId
WHERE 
    Q.PostTypeId = 1 -- Questions only
    AND A.PostTypeId = 2 -- Answers only
GROUP BY
    Q.Id;

-- Count the number of votes received per user and calculate their average reputation
SELECT 
    U.DisplayName,
    COUNT(V.Id) AS TotalVotesReceived,
    AVG(U.Reputation) AS AverageReputation
FROM 
    Votes V
JOIN 
    Users U ON V.UserId = U.Id
GROUP BY 
    U.DisplayName
ORDER BY 
    TotalVotesReceived DESC;

-- Analyze the frequency of closed posts and the corresponding close reasons
SELECT 
    C.Name AS CloseReason,
    COUNT(PH.Id) AS TotalClosedPosts
FROM 
    PostHistory PH
JOIN 
    CloseReasonTypes C ON PH.Comment::jsonb->>'closeReasonId'::int = C.Id
WHERE 
    PH.PostHistoryTypeId = 10 -- Closed posts
GROUP BY 
    C.Name
ORDER BY 
    TotalClosedPosts DESC;

-- Get the distribution of post edits over time
SELECT 
    date_trunc('month', PH.CreationDate) AS EditMonth,
    COUNT(*) AS TotalEdits
FROM 
    PostHistory PH
WHERE 
    PH.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, and Tags edits
GROUP BY 
    EditMonth
ORDER BY 
    EditMonth;

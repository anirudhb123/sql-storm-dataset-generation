-- Performance Benchmarking SQL Query

-- Fetching the total number of posts, average view count and the number of comments
SELECT 
    COUNT(P.Id) AS TotalPosts,
    AVG(P.ViewCount) AS AverageViewCount,
    COUNT(C.Id) AS TotalComments
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'; -- consider posts created in the last year

-- Fetching the top 10 users by reputation along with the number of posts they made
SELECT 
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id
ORDER BY 
    U.Reputation DESC
LIMIT 10;

-- Fetching the number of posts created by type (Questions, Answers, etc.)
SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    PT.Id
ORDER BY 
    TotalPosts DESC;

-- Analyzing the response time by measuring the average time between post creation and last activity
SELECT 
    AVG(EXTRACT(EPOCH FROM (P.LastActivityDate - P.CreationDate))) AS AvgResponseTimeSeconds,
    COUNT(P.Id) AS TotalPosts
FROM 
    Posts P
WHERE 
    P.LastActivityDate IS NOT NULL
    AND P.CreationDate >= NOW() - INTERVAL '1 year'; -- consider posts created in the last year

-- Fetching the most active tags based on the number of posts
SELECT 
    T.TagName,
    COUNT(P.Id) AS PostCount
FROM 
    Tags T
LEFT JOIN 
    Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
GROUP BY 
    T.Id
ORDER BY 
    PostCount DESC
LIMIT 10;

-- Benchmarking closed posts based on close reasons
SELECT 
    C.Name AS CloseReason,
    COUNT(P.Id) AS TotalClosedPosts
FROM 
    PostHistory PH
JOIN 
    CloseReasonTypes C ON PH.Comment::int = C.Id
JOIN 
    Posts P ON PH.PostId = P.Id
WHERE 
    PH.PostHistoryTypeId IN (10, 11) -- Close and Reopen events
GROUP BY 
    C.Id
ORDER BY 
    TotalClosedPosts DESC;

-- Calculating average votes per post
SELECT 
    AVG(VoteCount) AS AvgVotesPerPost
FROM 
    (SELECT 
        P.Id,
        COUNT(V.Id) AS VoteCount
     FROM 
        Posts P
     LEFT JOIN 
        Votes V ON P.Id = V.PostId
     GROUP BY 
        P.Id) AS PostVotes;

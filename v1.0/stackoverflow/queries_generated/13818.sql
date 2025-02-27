-- Performance benchmarking query for Stack Overflow schema

-- Retrieving user reputation, total posts, and average score of posts by each user
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AvgPostScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC;

-- Measuring the number of comments per post type
SELECT 
    PT.Name AS PostType,
    COUNT(C.Id) AS TotalComments
FROM 
    PostTypes PT
LEFT JOIN 
    Posts P ON PT.Id = P.PostTypeId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    PT.Name
ORDER BY 
    TotalComments DESC;

-- Time taken for each post type based on creation date
SELECT 
    PT.Name AS PostType,
    EXTRACT(EPOCH FROM AVG(P.CreationDate)) AS AvgCreationTime
FROM 
    PostTypes PT
JOIN 
    Posts P ON PT.Id = P.PostTypeId
GROUP BY 
    PT.Name
ORDER BY 
    AvgCreationTime DESC;

-- Daily active users over the last week
SELECT 
    DATE(LastAccessDate) AS AccessDate,
    COUNT(DISTINCT Id) AS ActiveUsers
FROM 
    Users
WHERE 
    LastAccessDate >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY 
    DATE(LastAccessDate)
ORDER BY 
    AccessDate;

-- Average number of votes per post type
SELECT 
    PT.Name AS PostType,
    AVG(VoteCount) AS AvgVotes
FROM 
    (SELECT 
        PostId, COUNT(Id) AS VoteCount
     FROM 
        Votes
     GROUP BY 
        PostId) AS V
JOIN 
    Posts P ON V.PostId = P.Id
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    PT.Name
ORDER BY 
    AvgVotes DESC;

-- Fetching closed posts and their close reasons
SELECT 
    P.Id AS PostId,
    P.Title,
    PH.CreationDate,
    PH.Comment AS CloseReason
FROM 
    Posts P
JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    PH.PostHistoryTypeId = 10  -- Post Closed
ORDER BY 
    PH.CreationDate DESC;

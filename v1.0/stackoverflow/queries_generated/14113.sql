-- Performance benchmarking query for Stack Overflow database

-- Query to retrieve the top users by reputation and their associated post details
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    COUNT(C.ID) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
    SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.Reputation > 0
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
ORDER BY 
    U.Reputation DESC, P.CreationDate DESC
LIMIT 100;

-- Query to analyze post history changes
SELECT 
    P.Id AS PostId,
    P.Title,
    PH.PostHistoryTypeId,
    PH.CreationDate AS ChangeDate,
    PH.UserDisplayName AS EditedBy,
    PH.Comment
FROM 
    Posts P
JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    PH.CreationDate >= NOW() - INTERVAL '30 days'
ORDER BY 
    PH.CreationDate DESC
LIMIT 100;

-- Query to get the most popular tags used in questions
SELECT 
    T.TagName,
    T.Count AS UsageCount,
    P.CreationDate AS LastUsedDate
FROM 
    Tags T
JOIN 
    Posts P ON T.ExcerptPostId = P.Id
WHERE 
    P.PostTypeId = 1
ORDER BY 
    T.Count DESC
LIMIT 50;

-- Performance benchmarking for the StackOverflow schema

-- Step 1: Measure the time to retrieve all posts with their related user and vote counts
EXPLAIN ANALYZE
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COALESCE(V.UpVotes, 0) AS UpVotes,
    COALESCE(V.DownVotes, 0) AS DownVotes,
    COALESCE(V.VoteCount, 0) AS VoteCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(Id) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) V ON P.Id = V.PostId
ORDER BY 
    P.CreationDate DESC
LIMIT 100;

-- Step 2: Measure the time to count the number of posts by type
EXPLAIN ANALYZE
SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;

-- Step 3: Measure the time to retrieve the most recent comments for each post
EXPLAIN ANALYZE
SELECT 
    P.Id AS PostId,
    P.Title,
    C.Text AS CommentText,
    C.CreationDate AS CommentDate
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    C.CreationDate = (
        SELECT MAX(C2.CreationDate)
        FROM Comments C2 
        WHERE C2.PostId = P.Id
    )
ORDER BY 
    P.CreationDate DESC
LIMIT 100;

-- Step 4: Measure the time to aggregate badges by user
EXPLAIN ANALYZE
SELECT 
    U.DisplayName,
    COUNT(B.Id) AS TotalBadges,
    SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    Users U
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.DisplayName
ORDER BY 
    TotalBadges DESC
LIMIT 100;

-- Performance Benchmarking SQL Query

-- Measure the average response time for fetching user interactions with posts, including votes and comments
WITH UserPostInteractions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserDisplayName,
        P.Id AS PostId,
        P.Title AS PostTitle,
        COALESCE(V.VoteTypeId, 'No Vote') AS VoteType,
        COALESCE(C.Text, 'No Comment') AS CommentText,
        COALESCE(C.CreationDate, 'N/A') AS CommentDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId AND C.UserId = U.Id
)
SELECT 
    COUNT(*) AS TotalInteractions,
    AVG(EXTRACT(EPOCH FROM (NOW() - U.CreationDate))) AS AvgResponseTime,
    UserDisplayName,
    PostId,
    PostTitle,
    VoteType,
    CommentText,
    CommentDate
FROM 
    UserPostInteractions U
GROUP BY 
    UserDisplayName, PostId, PostTitle, VoteType, CommentText, CommentDate
ORDER BY 
    TotalInteractions DESC
LIMIT 100;

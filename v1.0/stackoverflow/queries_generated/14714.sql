-- Performance Benchmarking Query
-- This query retrieves various statistics about posts, users, and their interactions,
-- providing insights into the overall performance of the Stack Overflow platform.

WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(A.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVoteCount,  -- Count of upvotes
        SUM(V.VoteTypeId = 3) AS DownVoteCount -- Count of downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.AcceptedAnswerId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, A.AcceptedAnswerId
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.VoteTypeId = 2) AS UpVoteGiven,
        SUM(V.VoteTypeId = 3) AS DownVoteGiven
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AcceptedAnswerId,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    US.UserId,
    US.DisplayName AS AuthorDisplayName,
    US.PostCount,
    US.BadgeCount,
    US.UpVoteGiven,
    US.DownVoteGiven
FROM 
    PostStatistics PS
LEFT JOIN 
    Users US ON PS.AcceptedAnswerId = US.Id
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;  -- Limit to 100 posts for performance benchmarking

-- Performance Benchmarking SQL Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts P
        LEFT JOIN Comments C ON P.Id = C.PostId
        LEFT JOIN Votes V ON P.Id = V.PostId
        LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    WHERE 
        P.CreationDate > NOW() - INTERVAL '1 year'  -- Filtering for posts created in the last year
    GROUP BY 
        P.Id
),
UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate > NOW() - INTERVAL '1 year'  -- Filtering for users created in the last year
    GROUP BY 
        U.Id
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.CommentCount,
    PS.VoteCount,
    PS.UpVotes,
    PS.DownVotes,
    US.UserId,
    US.DisplayName,
    US.PostCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.BadgeCount
FROM 
    PostStats PS
JOIN 
    UserStats US ON PS.PostId = US.UserId  -- Assuming we want to join based on user and post relationship
ORDER BY 
    PS.VoteCount DESC, PS.CommentCount DESC;  -- Order by most interacted posts

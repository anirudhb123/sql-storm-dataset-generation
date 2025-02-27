-- Performance benchmarking query to retrieve usage statistics of posts and users
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.PostTypeId,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.CreationDate AS UserCreationDate,
    US.PostCount,
    US.TotalScore,
    US.TotalUpVotes,
    US.TotalDownVotes
FROM 
    PostStatistics PS
JOIN 
    UserStatistics US ON PS.PostId = US.UserId
ORDER BY 
    PS.CreationDate DESC;

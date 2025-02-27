WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS Questions,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS Answers,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.UpVotes,
    US.DownVotes,
    US.BadgesEarned,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount
FROM 
    UserStats US
JOIN 
    PostStats PS ON US.UserId = PS.OwnerDisplayName
ORDER BY 
    US.Reputation DESC, PS.Score DESC
LIMIT 100;

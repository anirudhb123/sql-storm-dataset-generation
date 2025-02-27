-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId 
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVoteCount, -- UpMod votes
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVoteCount -- DownMod votes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.PostCount,
    US.TotalScore,
    US.BadgeCount,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.CommentCount,
    PD.UpVoteCount,
    PD.DownVoteCount
FROM 
    UserStats US
JOIN 
    PostDetails PD ON US.UserId = PD.OwnerUserId
ORDER BY 
    US.TotalScore DESC, PD.ViewCount DESC;

-- Performance Benchmarking Query for Stack Overflow Schema
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
VoteStats AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.BadgeCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    PS.TotalPosts,
    PS.TotalViews,
    PS.AvgScore,
    PS.LastPostDate,
    VS.TotalVotes,
    VS.UpVotes AS UserUpVotes,
    VS.DownVotes AS UserDownVotes
FROM 
    UserStats US
LEFT JOIN 
    PostStats PS ON US.UserId = PS.OwnerUserId
LEFT JOIN 
    VoteStats VS ON US.UserId = VS.UserId
ORDER BY 
    US.BadgeCount DESC, 
    US.TotalUpVotes DESC;

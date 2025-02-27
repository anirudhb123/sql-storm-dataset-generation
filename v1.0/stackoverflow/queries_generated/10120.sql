-- Performance Benchmarking Query for StackOverflow Schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(B.Class) AS TotalBadgeClass, 
        SUM(B.TagBased) AS TagBasedBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        PT.Name AS PostType
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
),
VoteStats AS (
    SELECT 
        V.PostId,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        V.PostId
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.CommentCount,
    US.TotalBadgeClass,
    US.TagBasedBadgeCount,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount AS PostAnswerCount,
    PS.CommentCount AS PostCommentCount,
    PS.FavoriteCount,
    PS.PostType,
    VS.TotalVotes,
    VS.UpVotes,
    VS.DownVotes
FROM 
    UserStats US
JOIN 
    PostStats PS ON PS.PostId = US.UserId
LEFT JOIN 
    VoteStats VS ON VS.PostId = PS.PostId
ORDER BY 
    US.Reputation DESC, PS.ViewCount DESC;

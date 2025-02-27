-- Performance Benchmarking Query

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    PS.VoteCount,
    US.UserId,
    US.GoldBadges,
    US.SilverBadges,
    US.BronzeBadges,
    US.AvgReputation
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostTypeId = U.AccountId
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.ViewCount DESC, PS.Score DESC;

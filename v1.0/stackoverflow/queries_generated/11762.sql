-- Performance benchmarking query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty 
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate AS UserCreationDate,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    PS.TotalBounty,
    US.UserId,
    US.Reputation,
    US.UserCreationDate,
    US.GoldBadges,
    US.SilverBadges,
    US.BronzeBadges
FROM 
    PostStats PS
LEFT JOIN 
    Users U ON PS.PostTypeId IN (1, 2) -- Only interested in questions and answers
LEFT JOIN 
    UserStats US ON U.Id = PS.OwnerUserId
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;

WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(COALESCE(V.VoteValue, 0)) AS TotalVotes, 
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        P.Score, 
        P.AnswerCount, 
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id 
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.AnswerCount
),
VoteStats AS (
    SELECT 
        P.Id AS PostId, 
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount,
        AVG(V.CreationDate) AS AvgVoteDate
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.Reputation, 
    U.PostCount, 
    U.TotalVotes, 
    U.GoldBadges, 
    U.SilverBadges, 
    U.BronzeBadges, 
    P.PostId, 
    P.Title, 
    P.ViewCount, 
    P.Score, 
    P.AnswerCount, 
    P.CommentCount, 
    V.VoteCount,
    V.AvgVoteDate
FROM 
    UserStats U
JOIN 
    PostStats P ON U.PostCount > 0
JOIN 
    VoteStats V ON P.PostId = V.PostId
ORDER BY 
    U.Reputation DESC, P.Score DESC
LIMIT 100;

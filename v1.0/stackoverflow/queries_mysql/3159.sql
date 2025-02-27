
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN VB.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN VB.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        @userRank := @userRank + 1 AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Votes VB ON U.Id = VB.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId,
        (SELECT @userRank := 0) r
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PostScore AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        @scoreRank := IF(@currentOwnerUserId = P.OwnerUserId, @scoreRank + 1, 1) AS ScoreRank,
        @currentOwnerUserId := P.OwnerUserId
    FROM 
        Posts P,
        (SELECT @scoreRank := 0, @currentOwnerUserId := '') r
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        P.OwnerUserId, P.Score DESC
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    PS.PostId,
    PS.Score,
    PS.CreationDate,
    PS.ScoreRank
FROM 
    UserStats U
JOIN 
    PostScore PS ON U.UserId = PS.OwnerUserId
WHERE 
    (U.UpVotes - U.DownVotes) >= 10
    AND PS.ScoreRank = 1
    AND PS.CreationDate IS NOT NULL
ORDER BY 
    U.Reputation DESC, PS.Score DESC
LIMIT 50;

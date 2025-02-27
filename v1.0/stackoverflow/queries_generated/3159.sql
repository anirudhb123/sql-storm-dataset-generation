WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(VB.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(VB.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Votes VB ON U.Id = VB.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),

PostScore AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
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

-- Additional checks for active users and their top posts
UNION 

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
    Users U
LEFT JOIN 
    PostScore PS ON U.Id = PS.OwnerUserId
WHERE 
    U.LastAccessDate >= NOW() - INTERVAL '30 days'
    AND PS.Score IS NULL
ORDER BY 
    U.Reputation DESC
LIMIT 50;

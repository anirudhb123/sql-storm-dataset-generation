
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        @row_number:=IF(@current_user_id = P.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_user_id := P.OwnerUserId
    FROM 
        Posts P, (SELECT @row_number := 0, @current_user_id := NULL) AS init
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.PostCount,
        UR.UpVoteCount,
        UR.DownVoteCount
    FROM 
        UserReputation UR
    WHERE 
        UR.Reputation > 1000 AND UR.PostCount > 5
    ORDER BY 
        UR.Reputation DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName, 
    TU.Reputation,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    (TU.UpVoteCount - TU.DownVoteCount) AS VoteBalance
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPosts RP ON TU.UserId = RP.OwnerUserId AND RP.PostRank = 1
WHERE 
    TU.Reputation IS NOT NULL
ORDER BY 
    VoteBalance DESC, TU.Reputation DESC;

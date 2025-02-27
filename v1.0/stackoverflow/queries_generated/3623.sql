WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (10, 12) THEN 1 ELSE 0 END), 0) AS DeletedPosts
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        UA.UpVotes,
        UA.DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM UserScore UA
    JOIN Users U ON UA.UserId = U.Id
    WHERE U.Reputation > 100
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    PA.PostId,
    PA.Title,
    PA.Score,
    PA.CreationDate AS PostDate,
    COALESCE(PD.DeletedPosts, 0) AS TotalDeletedPosts,
    NTILE(5) OVER (ORDER BY PA.Score DESC) AS ScoreCategory
FROM TopUsers U
JOIN PostActivity PA ON U.UserId = PA.OwnerUserId
LEFT JOIN UserScore PD ON U.UserId = PD.UserId
WHERE U.UserRank <= 10
AND PA.PostRank <= 5
ORDER BY U.Reputation DESC, PA.Score DESC;

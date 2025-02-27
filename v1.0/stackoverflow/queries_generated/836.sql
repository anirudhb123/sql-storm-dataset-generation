WITH UserReputationCTE AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation > 1000
),
TopPostsCTE AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT
    U.DisplayName AS UserName,
    U.Reputation,
    T.Title AS PostTitle,
    T.Score AS PostScore,
    COALESCE(T.ViewCount, 0) AS PostViewCount,
    T.CreationDate AS PostCreationDate
FROM UserReputationCTE U
LEFT JOIN TopPostsCTE T ON U.UserId = T.OwnerDisplayName
WHERE T.PostRank <= 5 OR T.PostRank IS NULL
ORDER BY U.Reputation DESC, T.Score DESC;

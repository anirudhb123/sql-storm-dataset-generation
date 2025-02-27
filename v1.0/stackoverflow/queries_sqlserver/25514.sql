
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation > 0
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.OwnerUserId,
        P.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
),
PostTagStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT T.TagName) AS TagCount,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM Posts P
    CROSS APPLY STRING_SPLIT(P.Tags, '>') AS T 
    WHERE T.Value IS NOT NULL
    GROUP BY P.Id
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY PH.PostId
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    PTS.TagCount,
    PTS.Tags,
    PHS.EditCount,
    PHS.LastEditDate
FROM RankedUsers RU
JOIN RecentPosts RP ON RU.UserId = RP.OwnerUserId AND RP.PostRank = 1
JOIN PostTagStats PTS ON RP.PostId = PTS.PostId
JOIN PostHistoryStats PHS ON RP.PostId = PHS.PostId
WHERE RU.ReputationRank <= 10
ORDER BY RU.Reputation DESC, RP.CreationDate DESC;

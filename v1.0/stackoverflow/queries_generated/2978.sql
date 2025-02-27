WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        COALESCE(PH.Count, 0) AS EditCount,
        CASE 
            WHEN RP.Score > 100 THEN 'Hot'
            WHEN RP.Score BETWEEN 50 AND 100 THEN 'Moderate'
            ELSE 'Cold'
        END AS Popularity
    FROM RankedPosts RP
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS Count 
        FROM PostHistory 
        WHERE PostHistoryTypeId IN (4, 5) 
        GROUP BY PostId
    ) PH ON RP.PostId = PH.PostId
    WHERE RP.PostRank = 1
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.OwnerDisplayName,
    PS.EditCount,
    PS.Popularity,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PS.PostId) AS CommentCount
FROM PostStatistics PS
WHERE PS.EditCount > 0
ORDER BY PS.Score DESC, PS.ViewCount DESC
LIMIT 10
UNION ALL
SELECT 
    T.Id AS PostId,
    T.TagName AS Title,
    NULL AS CreationDate,
    SUM(T.Count) AS Score,
    NULL AS ViewCount,
    NULL AS OwnerDisplayName,
    NULL AS EditCount,
    'Tag' AS Popularity,
    NULL AS CommentCount
FROM Tags T
WHERE T.Count > 100
GROUP BY T.Id, T.TagName
ORDER BY SUM(T.Count) DESC
LIMIT 5;

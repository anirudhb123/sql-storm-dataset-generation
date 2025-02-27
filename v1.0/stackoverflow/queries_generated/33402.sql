WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore,
        COUNT(V.Id) AS VoteCount,
        AVG(U.Reputation) AS AvgUserReputation
    FROM
        Posts P
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
),
ClosedPosts AS (
    SELECT
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CAST(PHT.Name AS VARCHAR), ', ') AS CloseReasons
    FROM
        PostHistory PH
    JOIN
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE
        PHT.Id IN (10, 11) -- Close or Reopen reasons
    GROUP BY
        PH.PostId
),
TagPostCounts AS (
    SELECT
        T.Id AS TagId,
        T.TagName,
        COUNT(PT.PostId) AS PostCount
    FROM
        Tags T
    LEFT JOIN
        Posts PT ON PT.Tags LIKE '%' || T.TagName || '%'
    GROUP BY
        T.Id, T.TagName
)
SELECT
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.CreationDate,
    RP.RankByScore,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    COALESCE(CP.CloseReasons, 'None') AS CloseReasons,
    (SELECT 
        COUNT(*) 
     FROM 
        Badges B 
     WHERE 
        B.UserId = P.OwnerUserId AND B.Class = 1) AS GoldBadgeCount,
    TPC.TagCount
FROM
    RankedPosts RP
LEFT JOIN
    ClosedPosts CP ON RP.PostId = CP.PostId
JOIN
    (
        SELECT
            T.Id AS TagId,
            COUNT(PT.PostId) AS TagCount
        FROM
            Tags T
        JOIN
            Posts PT ON PT.Tags LIKE '%' || T.TagName || '%'
        GROUP BY
            T.Id
    ) TPC ON RP.PostId IN (SELECT unnest(string_to_array(PT.Tags, ','))::int)
WHERE
    RP.RankByScore <= 5
ORDER BY
    RP.Score DESC, RP.ViewCount DESC;

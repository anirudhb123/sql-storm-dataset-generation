WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer'
            ELSE 'Not Accepted Answer'
        END AS AnswerStatus,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
        AND P.Score >= 0
),
UserWithBadges AS (
    SELECT 
        U.Id AS UserId,
        ARRAY_AGG(B.Name) AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostHistoryChanges AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        ARRAY_AGG(DISTINCT PH.CreationDate ORDER BY PH.CreationDate) AS ChangeTimestamps
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    RP.AnswerStatus,
    UWB.BadgeNames,
    UWB.BadgeCount,
    PHC.ChangeCount,
    PHC.ChangeTimestamps
FROM 
    RankedPosts RP
LEFT JOIN 
    Users U ON RP.OwnerDisplayName = U.DisplayName
LEFT JOIN 
    UserWithBadges UWB ON U.Id = UWB.UserId
LEFT JOIN 
    PostHistoryChanges PHC ON RP.PostId = PHC.PostId
WHERE 
    RP.PostRank <= 3
ORDER BY 
    RP.Score DESC, RP.CreationDate ASC
LIMIT 100;

-- Additional notes: 
-- - This query ranks users' posts from the last year, aggregates badge information,
--   counts post history changes, and brings it all together.
-- - It limits results to the top 3 posts per user and orders by score and creation date.
-- - Uses CTEs to simplify complex aggregations and joins.
-- - The selection of array aggregations and potential NULLs adds complexity in dealing with empty badges or history.

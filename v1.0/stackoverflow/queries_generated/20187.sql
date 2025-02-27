WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        (SELECT COUNT(*)
         FROM Comments C
         WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT STRING_AGG(T.TagName, ', ') 
         FROM Tags T
         WHERE T.Id IN (SELECT UNNEST(string_to_array(P.Tags, '>'))::int)) AS TagsList
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),

UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),

ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PH.Text,
        P.Score,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank,
        COALESCE(CR.Name, 'Unknown') AS CloseReason
    FROM 
        PostHistory PH
    LEFT JOIN CloseReasonTypes CR ON PH.Comment::int = CR.Id
    LEFT JOIN Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
)

SELECT 
    RP.Title,
    RP.Score,
    RP.CommentCount,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.BadgeCount,
    UA.TotalBounty,
    RPT.CloseReason AS LastCloseReason,
    RP.TagsList
FROM 
    RankedPosts RP
JOIN UserActivity UA ON RP.AcceptedAnswerId = UA.UserId
LEFT JOIN ClosedPostHistory RPT ON RP.Id = RPT.PostId AND RPT.HistoryRank = 1
WHERE 
    RP.Rank = 1 
    AND (RP.Score > 0 OR RP.TagsList LIKE '%SQL%')
ORDER BY 
    RP.CreationDate DESC NULLS LAST;

-- Additional Note: This query is designed to pull a detailed summary of user's most recent 
-- posts within the last year while also providing insights regarding the users' activity, 
-- badges earned, and any recent closure reasons for their posts, while incorporating ranked 
-- rows, correlated subqueries, and advanced joins with a focus on null handling and string
-- aggregation.

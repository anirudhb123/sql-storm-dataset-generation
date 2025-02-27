WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.PostTypeId = 1 -- Only Questions
        AND P.Score > 0 -- Only questions that have been positively scored
),
UserBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id
),
PostHistoryDetails AS (
    SELECT
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.Comment,
        PH.PostHistoryTypeId,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RevisionRank
    FROM
        PostHistory PH
    WHERE
        PH.PostHistoryTypeId IN (10, 11) -- Only relevant Post History actions (Close and Reopen)
),
PostViewCounts AS (
    SELECT
        P.Id AS PostId,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(V.Id) AS VoteCount
    FROM
        Posts P
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        P.Id
)
SELECT
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.OwnerName,
    UB.BadgeCount,
    UB.BadgeNames,
    PH.Comment,
    PH.CreationDate AS HistoryDate,
    PV.TotalBountyAmount,
    PV.VoteCount
FROM
    RankedPosts RP
LEFT JOIN
    UserBadges UB ON RP.OwnerUserId = UB.UserId
LEFT JOIN
    PostHistoryDetails PH ON RP.PostId = PH.PostId AND PH.RevisionRank = 1 -- Most recent history action
LEFT JOIN
    PostViewCounts PV ON RP.PostId = PV.PostId
WHERE
    RP.PostRank <= 5 -- Only the last 5 posts per user
ORDER BY
    RP.CreationDate DESC;


WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerName,
        @PostRank := IF(@currentUserId = P.OwnerUserId, @PostRank + 1, 1) AS PostRank,
        @currentUserId := P.OwnerUserId
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id,
        (SELECT @PostRank := 0, @currentUserId := NULL) AS vars
    WHERE
        P.PostTypeId = 1 
        AND P.Score > 0 
    ORDER BY
        P.OwnerUserId, P.CreationDate DESC
),
UserBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name SEPARATOR ', ') AS BadgeNames
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
        @RevisionRank := IF(@currentPostId = PH.PostId, @RevisionRank + 1, 1) AS RevisionRank,
        @currentPostId := PH.PostId
    FROM
        PostHistory PH,
        (SELECT @RevisionRank := 0, @currentPostId := NULL) AS vars
    WHERE
        PH.PostHistoryTypeId IN (10, 11) 
    ORDER BY
        PH.PostId, PH.CreationDate DESC
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
    PostHistoryDetails PH ON RP.PostId = PH.PostId AND PH.RevisionRank = 1 
LEFT JOIN
    PostViewCounts PV ON RP.PostId = PV.PostId
WHERE
    RP.PostRank <= 5 
ORDER BY
    RP.CreationDate DESC;

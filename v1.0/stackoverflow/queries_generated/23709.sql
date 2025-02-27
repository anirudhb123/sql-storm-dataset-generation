WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.PostTypeId,
        P.Score,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM
        Posts P
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.PostTypeId, P.Score
),
UserBadges AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName
),
PostHistoryInfo AS (
    SELECT
        PH.PostId,
        MAX(CASE WHEN PHT.Name = 'Post Closed' THEN PH.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN PHT.Name = 'Post Reopened' THEN PH.CreationDate END) AS LastReopenedDate
    FROM
        PostHistory PH
    JOIN
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY
        PH.PostId
)

SELECT
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.UpVotesCount,
    RP.DownVotesCount,
    UB.UserId,
    UB.DisplayName,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    COALESCE(PHI.LastClosedDate, 'Never Closed') AS LastClosedDate,
    COALESCE(PHI.LastReopenedDate, 'Never Reopened') AS LastReopenedDate,
    CASE
        WHEN RP.PostTypeId = 1 THEN 'Question'
        WHEN RP.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostTypeLabel,
    CASE
        WHEN RP.Score > 0 THEN 'Popular'
        WHEN RP.Score = 0 THEN 'Neutral'
        ELSE 'Unpopular'
    END AS PopularityStatus
FROM
    RankedPosts RP
JOIN
    Users U ON RP.Id = U.Id
LEFT JOIN
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN
    PostHistoryInfo PHI ON RP.PostId = PHI.PostId
WHERE
    (RP.UpVotesCount - RP.DownVotesCount) > 10
    OR (RP.Score BETWEEN -5 AND 5 AND RP.Rank <= 10)
ORDER BY
    RP.CreationDate DESC, RP.Score DESC
FETCH FIRST 100 ROWS ONLY;

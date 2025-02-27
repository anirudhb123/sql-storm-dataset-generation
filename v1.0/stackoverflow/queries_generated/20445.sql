WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE 
            WHEN B.Class = 1 THEN 1 
            END) AS GoldBadges,
        COUNT(CASE 
            WHEN B.Class = 2 THEN 1 
            END) AS SilverBadges,
        COUNT(CASE 
            WHEN B.Class = 3 THEN 1 
            END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId 
    GROUP BY U.Id
),
PostSummary AS (
    SELECT
        P.Id AS PostId,
        P.PostTypeId,
        COALESCE(A.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS AuthorName,
        COUNT(CASE 
            WHEN C.Id IS NOT NULL THEN 1 
            END) AS CommentCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId 
    LEFT JOIN Users U ON P.OwnerUserId = U.Id 
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId 
    LEFT JOIN Tags T ON PL.RelatedPostId = T.Id
    LEFT JOIN Posts A ON P.AcceptedAnswerId = A.Id
    WHERE P.CreationDate >= '2023-01-01' AND P.Score > 0
    GROUP BY P.Id, P.PostTypeId, A.AcceptedAnswerId, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Score,
        PS.ViewCount,
        PS.AuthorName,
        ROW_NUMBER() OVER (PARTITION BY PS.AuthorName ORDER BY PS.Score DESC) AS Rank
    FROM PostSummary PS
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PS.PostId,
    PS.AuthorName,
    PS.Score,
    PS.ViewCount,
    COUNT(DISTINCT C.Id) AS TotalComments,
    CASE 
        WHEN PS.Score IS NULL THEN 'No Score'
        WHEN PS.Score >= 100 THEN 'High Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM Users U
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN PostSummary PS ON U.Id = PS.AuthorName
LEFT JOIN Comments C ON PS.PostId = C.PostId
LEFT JOIN Tags T ON T.ExcerptPostId = PS.PostId
WHERE 
    U.LastAccessDate >= NOW() - INTERVAL '1 month'
GROUP BY 
    U.Id, U.DisplayName, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges, PS.PostId, PS.Score, PS.ViewCount
HAVING 
    SUM(CASE WHEN PS.Score IS NOT NULL THEN 1 ELSE 0 END) > 0 AND 
    COUNT(DISTINCT PS.PostId) > 5
ORDER BY 
    U.Reputation DESC, ScoreCategory, PS.ViewCount DESC;

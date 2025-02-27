
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        @row_number := IF(@prev_post_type = P.PostTypeId, @row_number + 1, 1) AS RankByScore,
        @prev_post_type := P.PostTypeId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COALESCE(PH.Comment, 'No close reason provided') AS CloseReason
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.RankByScore,
        RP.UpvoteCount,
        RP.DownvoteCount,
        CASE 
            WHEN RP.UpvoteCount IS NULL THEN 'None'
            WHEN RP.UpvoteCount - RP.DownvoteCount >= 0 THEN 'Positive'
            ELSE 'Negative'
        END AS VoteSentiment
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankByScore <= 10
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.Score,
    FP.ViewCount,
    FP.VoteSentiment,
    SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    FilteredPosts FP
LEFT JOIN 
    Badges B ON FP.PostId = B.UserId
GROUP BY 
    FP.PostId, FP.Title, FP.CreationDate, FP.Score, FP.ViewCount, FP.VoteSentiment
ORDER BY 
    FP.Score DESC, FP.CreationDate DESC;

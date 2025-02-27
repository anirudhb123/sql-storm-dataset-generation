WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
PostScoreDetails AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(V.VoteScore, 0) AS TotalScore,
        COUNT(C.Id) AS CommentCount,
        P.ViewCount,
        P.CreationDate
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 
                     WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' AND
        P.Score > 0
    GROUP BY 
        P.Id, P.OwnerUserId, P.ViewCount
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(PSD.TotalScore, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId IN (1, 2)
    LEFT JOIN 
        PostScoreDetails PSD ON P.Id = PSD.PostId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UBC.BadgeCount,
    UBC.GoldBadges,
    UBC.SilverBadges,
    UBC.BronzeBadges,
    UPS.TotalPosts,
    UPS.TotalScore,
    CASE 
        WHEN UPS.TotalScore IS NULL THEN 'No Score'
        WHEN UPS.TotalScore > 100 THEN 'High Score'
        ELSE 'Moderate Score'
    END AS ScoreCategory
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN 
    UserPostStats UPS ON U.Id = UPS.UserId
WHERE 
    U.LastAccessDate >= NOW() - INTERVAL '30 days'
ORDER BY 
    ScoreCategory DESC,
    U.Reputation DESC,
    U.DisplayName ASC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY
WITH TIES

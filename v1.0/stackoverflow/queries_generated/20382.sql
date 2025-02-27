WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.Score, 0) AS PostScore,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        MAX(BH.UserDisplayName) AS LastEditor
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5) -- Title/Body edits
    LEFT JOIN 
        Users BH ON PH.UserId = BH.Id
    GROUP BY 
        P.Id
),
RankedPosts AS (
    SELECT 
        PD.*, 
        DENSE_RANK() OVER (ORDER BY PD.PostScore DESC, PD.ViewCount DESC) AS PostRank
    FROM 
        PostDetails PD
),
UserPostStats AS (
    SELECT 
        U.UserId, 
        U.DisplayName, 
        SUM(CASE WHEN RP.OwnerUserId = U.UserId THEN 1 ELSE 0 END) AS TotalPosts,
        SUM(CASE WHEN RP.PostScore > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts
    FROM 
        UserBadges U
    LEFT JOIN 
        RankedPosts RP ON U.UserId = RP.OwnerUserId
    GROUP BY 
        U.UserId, 
        U.DisplayName
)
SELECT 
    U.DisplayName,
    CASE 
        WHEN U.GoldBadges > 0 THEN 'Gold'
        WHEN U.SilverBadges > 0 THEN 'Silver'
        WHEN U.BronzeBadges > 0 THEN 'Bronze'
        ELSE 'No Badges'
    END AS BadgeCategory,
    UPS.TotalPosts, 
    UPS.PositiveScorePosts,
    R.PostRank,
    R.Title,
    COALESCE(R.LastEditor, 'N/A') AS LastEditorName,
    R.PostScore,
    R.CommentCount
FROM 
    UserBadges U
LEFT JOIN 
    UserPostStats UPS ON U.UserId = UPS.UserId
LEFT JOIN 
    RankedPosts R ON R.OwnerUserId = U.UserId
WHERE 
    (U.ReputationRank <= 50 OR UPS.TotalPosts > 10) -- Limiting the selection based on reputation or total posts
ORDER BY 
    U.Reputation DESC, 
    R.PostRank;

WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank,
        P.AcceptedAnswerId,
        COALESCE(PA.OwnerUserId, -1) AS AnswerOwnerId
    FROM 
        Posts P
    LEFT JOIN 
        Posts PA ON P.Id = PA.Id AND P.AcceptedAnswerId = PA.Id
    WHERE 
        P.IsModeratorOnly IS NULL
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostUserInteractions AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS TotalVotes,
        COUNT(C.Id) AS TotalComments,
        AVG(V.BountyAmount) AS AvgBounty
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    UB.UserId,
    UB.TotalBadges,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PUI.TotalVotes,
    PUI.TotalComments,
    COALESCE(PUI.AvgBounty, 0) AS AvgBounty,
    CASE 
        WHEN RP.Rank <= 5 THEN 'Top 5' 
        ELSE 'Below Top 5' 
    END AS RankCategory,
    CASE 
        WHEN PUI.TotalVotes = 0 AND RP.Score > 0 THEN 'Potential Overlooked' 
        ELSE 'Active Engagement' 
    END AS EngagementStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    UserBadges UB ON RP.AnswerOwnerId = UB.UserId
LEFT JOIN 
    PostUserInteractions PUI ON RP.PostId = PUI.PostId
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;

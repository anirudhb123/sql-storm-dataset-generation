
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostAggregates AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    WHERE 
        P.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
    GROUP BY 
        P.Id, P.OwnerUserId
),
RankedPosts AS (
    SELECT 
        PA.PostId,
        PA.OwnerUserId,
        PA.CommentCount,
        PA.TotalBounty,
        @row_num := IF(@prev_owner = PA.OwnerUserId, @row_num + 1, 1) AS CommentRank,
        @prev_owner := PA.OwnerUserId,
        DENSE_RANK() OVER (ORDER BY PA.TotalBounty DESC) AS BountyRank
    FROM 
        PostAggregates PA,
        (SELECT @row_num := 0, @prev_owner := NULL) AS vars
    ORDER BY 
        PA.OwnerUserId, PA.CommentCount DESC
),
UserDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
        RP.PostId,
        RP.CommentCount,
        RP.TotalBounty,
        RP.CommentRank,
        RP.BountyRank
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        RankedPosts RP ON U.Id = RP.OwnerUserId
    WHERE 
        U.Reputation > 0
)
SELECT 
    UD.DisplayName,
    UD.Reputation,
    UD.GoldBadges,
    UD.SilverBadges,
    UD.BronzeBadges,
    UD.CommentCount,
    CASE 
        WHEN UD.TotalBounty > 0 THEN 'Has Bounties'
        ELSE 'No Bounties'
    END AS BountyStatus,
    CASE 
        WHEN UD.CommentRank IS NULL THEN 'N/A'
        ELSE CAST(UD.CommentRank AS CHAR)
    END AS CommentRank,
    CASE 
        WHEN UD.BountyRank IS NULL THEN 'N/A'
        ELSE CAST(UD.BountyRank AS CHAR)
    END AS BountyRank
FROM 
    UserDetails UD
WHERE 
    (UD.CommentCount > 0 OR UD.TotalBounty > 0)
    AND 
    (UD.GoldBadges + UD.SilverBadges + UD.BronzeBadges) > 0
ORDER BY 
    UD.Reputation DESC, 
    UD.CommentCount DESC;

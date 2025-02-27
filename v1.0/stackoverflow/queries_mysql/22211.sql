
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
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(A.OwnerUserId, -1) AS AcceptedAnswerUser,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        @row_num := IF(@prev_user = P.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @prev_user := P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    CROSS JOIN (SELECT @row_num := 0, @prev_user := NULL) AS vars
    WHERE 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    GROUP BY 
        P.Id, P.Title, P.ViewCount, A.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        MAX(P.CreationDate) AS LastActive,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(
            CASE WHEN V.VoteTypeId = 2 THEN 1
                 WHEN V.VoteTypeId = 3 THEN -1
                 ELSE 0 END
        ) AS VoteNet
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
CombinedReport AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        UA.LastActive,
        UA.TotalBounty,
        UA.TotalPosts,
        UA.VoteNet,
        PD.PostId,
        PD.Title,
        PD.ViewCount,
        PD.CommentCount
    FROM 
        Users U
    JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    JOIN 
        UserActivity UA ON U.Id = UA.UserId
    LEFT JOIN 
        PostDetails PD ON U.Id = PD.AcceptedAnswerUser
)
SELECT 
    CR.UserId,
    CR.DisplayName,
    CR.Reputation,
    CR.GoldBadges,
    CR.SilverBadges,
    CR.BronzeBadges,
    CR.LastActive,
    CR.TotalBounty,
    CR.TotalPosts,
    CR.VoteNet,
    COALESCE(PD.Title, 'No Accepted Answers') AS Title,
    COALESCE(PD.ViewCount, 0) AS ViewCount,
    COALESCE(PD.CommentCount, 0) AS CommentCount
FROM 
    CombinedReport CR
LEFT JOIN 
    PostDetails PD ON CR.UserId = PD.AcceptedAnswerUser
WHERE 
    (CR.TotalBounty > 100 OR CR.Reputation > 1000)
    AND (CR.GoldBadges > 0 OR CR.SilverBadges > 0 OR CR.BronzeBadges > 0)
ORDER BY 
    CR.Reputation DESC, CR.LastActive DESC
LIMIT 100;

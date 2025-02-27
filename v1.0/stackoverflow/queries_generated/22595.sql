WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN,
        COUNT(*) OVER (PARTITION BY P.OwnerUserId) AS TotalPosts
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),

UserSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        AVG(RN.TotalPosts) AS AvgPostsPerUser
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        RankedPosts RN ON U.Id = RN.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),

PostHistoryData AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        P.Title,
        PT.Name AS PostType,
        CASE 
            WHEN PH.Comment IS NOT NULL THEN PH.Comment 
            ELSE 'No Comments' 
        END AS EditComment,
        LAG(PH.CreationDate) OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate) AS PreviousEditDate
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
),

RecentActivity AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '3 months'
    GROUP BY 
        PH.UserId, PH.PostId
),

FinalReport AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.GoldBadges,
        US.SilverBadges,
        US.BronzeBadges,
        US.TotalBounty,
        R.PostId,
        PHD.EditComment,
        R.LastEditDate,
        R.EditCount,
        COALESCE(R.EditCount, 0) AS SummaryEditCount,
        CASE 
            WHEN PHD.PreviousEditDate IS NULL THEN 'First Edit'
            ELSE 'Edited After: ' || TO_CHAR(PHD.PreviousEditDate, 'YYYY-MM-DD HH24:MI:SS')
        END AS EditContext
    FROM 
        UserSummary US
    LEFT JOIN 
        RecentActivity R ON US.UserId = R.UserId
    LEFT JOIN 
        PostHistoryData PHD ON R.PostId = PHD.PostId
    ORDER BY 
        US.Reputation DESC, R.LastEditDate DESC
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalBounty,
    PostId,
    EditComment,
    LastEditDate,
    EditCount,
    SummaryEditCount,
    EditContext
FROM 
    FinalReport
WHERE 
    PostId IS NOT NULL
ORDER BY 
    Reputation DESC, EditCount DESC;

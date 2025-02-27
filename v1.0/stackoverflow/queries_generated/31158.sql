WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.ParentId,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
),
UserScoreDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS TotalScore,
        AVG(P.Score) AS AvgScore,
        COALESCE(SUM(B.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(B.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(B.Class = 3), 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment,
        PH.Text AS CloseReason
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
),
TopTags AS (
    SELECT 
        T.TagName,
        T.Count,
        ROW_NUMBER() OVER (ORDER BY T.Count DESC) AS TagRank
    FROM 
        Tags T
    WHERE 
        T.IsModeratorOnly = 0
)
SELECT 
    P.Title AS PostTitle,
    U.DisplayName AS Author,
    U.TotalPosts,
    U.TotalScore,
    U.AvgScore,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    C.CloseReason,
    TH.TagName AS TopTag,
    TH.TagRank
FROM 
    RecursivePostHierarchy RP 
JOIN 
    UserScoreDetails U ON RP.OwnerUserId = U.UserId
LEFT JOIN 
    ClosedPosts C ON RP.PostId = C.PostId
LEFT JOIN 
    TopTags TH ON TH.TagRank <= 5
WHERE 
    U.TotalScore > 100 
    AND RP.Level = 0
ORDER BY 
    U.TotalScore DESC, 
    U.TotalPosts DESC, 
    TH.TagRank;

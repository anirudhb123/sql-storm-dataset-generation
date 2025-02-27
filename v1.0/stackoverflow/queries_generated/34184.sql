WITH RECURSIVE UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(V.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(COALESCE(V.Score, 0)) DESC) AS rn
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
FilteredUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalScore,
        TotalViews
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 5 -- Filter users who have posted more than 5 posts
),
PostHistoryData AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditCount,
        AVG(EXTRACT(EPOCH FROM (PH.CreationDate - LAG(PH.CreationDate) OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate))) / 60) AS AvgEditInterval
    FROM 
        PostHistory PH
    INNER JOIN 
        Posts P ON PH.PostId = P.Id
    GROUP BY 
        PH.UserId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
FinalStats AS (
    SELECT 
        FU.UserId,
        FU.DisplayName,
        FU.TotalPosts,
        FU.TotalScore,
        FU.TotalViews,
        COALESCE(PHD.EditCount, 0) AS EditCount,
        COALESCE(PHD.AvgEditInterval, 0) AS AvgEditInterval,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM 
        FilteredUsers FU
    LEFT JOIN 
        PostHistoryData PHD ON FU.UserId = PHD.UserId
    LEFT JOIN 
        UserBadges UB ON FU.UserId = UB.UserId
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalScore,
    TotalViews,
    EditCount,
    AvgEditInterval,
    BadgeCount,
    CASE 
        WHEN TotalScore > 100 THEN 'High Scorer'
        WHEN TotalScore BETWEEN 50 AND 100 THEN 'Moderate Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory,
    CASE 
        WHEN BadgeCount > 5 THEN 'Veteran User'
        ELSE 'New User'
    END AS UserType
FROM 
    FinalStats
ORDER BY 
    TotalScore DESC, TotalPosts DESC;

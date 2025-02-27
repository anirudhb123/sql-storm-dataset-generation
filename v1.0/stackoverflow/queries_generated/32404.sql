WITH RECURSIVE UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        SUM(P.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(P.ViewCount) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostDate,
        P.Score,
        PH.UserDisplayName,
        PH.CreationDate AS HistoryDate,
        PT.Name AS PostType
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostMetrics AS (
    SELECT 
        PA.UserDisplayName,
        COUNT(PA.PostId) AS TotalPosts,
        SUM(PA.Score) AS TotalScore,
        AVG(PA.Score) AS AverageScore,
        COUNT(DISTINCT PA.PostId) AS UniquePosts
    FROM 
        PostActivity PA
    GROUP BY 
        PA.UserDisplayName
)

SELECT 
    U.DisplayName,
    UPS.PostCount,
    UPS.UpvotedPosts,
    UPS.DownvotedPosts,
    UPS.TotalViews,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PM.TotalPosts,
    PM.TotalScore,
    PM.AverageScore,
    PM.UniquePosts
FROM 
    UserPostStats UPS
LEFT JOIN 
    UserBadges UB ON UPS.UserId = UB.UserId
LEFT JOIN 
    PostMetrics PM ON UPS.DisplayName = PM.UserDisplayName
WHERE 
    UPS.Rank <= 10
ORDER BY 
    UPS.TotalViews DESC;

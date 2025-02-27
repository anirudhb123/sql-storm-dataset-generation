WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(PH.CreationDate) AS LastActionDate
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
),
PostLinkCount AS (
    SELECT 
        PL.PostId,
        COUNT(PL.RelatedPostId) AS TotalLinks
    FROM 
        PostLinks PL
    GROUP BY 
        PL.PostId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
FinalStats AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.PositivePosts,
        UPS.AverageScore,
        UPS.LastPostDate,
        COALESCE(PH.HistoryCount, 0) AS PostHistoryCount,
        COALESCE(PLC.TotalLinks, 0) AS TotalPostLinks,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(UB.BadgeNames, 'None') AS BadgeList
    FROM 
        UserPostStats UPS
    LEFT JOIN 
        PostHistoryStats PH ON UPS.TotalPosts > 0 AND UPS.UserId IN (SELECT DISTINCT PH.UserId FROM PostHistory PH)
    LEFT JOIN 
        PostLinkCount PLC ON UPS.TotalPosts > 0 AND UPS.UserId IN (SELECT DISTINCT P.OwnerUserId FROM Posts P WHERE P.Id = PLC.PostId)
    LEFT JOIN 
        UserBadges UB ON UPS.UserId = UB.UserId
)
SELECT 
    *,
    CASE 
        WHEN TotalPosts = 0 THEN 'No Posts Yet'
        WHEN TotalPosts < 5 THEN 'New Contributor'
        WHEN TotalPosts < 20 THEN 'Growing Contributor'
        ELSE 'Established Contributor'
    END AS ContributorLevel,
    CASE 
        WHEN LastPostDate IS NULL THEN 'Never Posted'
        WHEN LastPostDate < NOW() - INTERVAL '1 month' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    FinalStats
WHERE 
    TotalBadges > 0
ORDER BY 
    AverageScore DESC, DisplayName ASC;

WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(B.Class) AS TotalBadgeClass,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ClosedPostStats AS (
    SELECT 
        Ph.UserId,
        COUNT(*) AS ClosedPostCount,
        MAX(Ph.CreationDate) AS LastClosureDate
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId = 10
    GROUP BY 
        Ph.UserId
),
FinalStats AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        COALESCE(CPS.ClosedPostCount, 0) AS ClosedPostCount,
        CPS.LastClosureDate
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        ClosedPostStats CPS ON U.Id = CPS.UserId
)
SELECT 
    F.UserId,
    F.GoldBadges,
    F.SilverBadges,
    F.BronzeBadges,
    F.QuestionCount,
    F.AnswerCount,
    F.TotalViews,
    F.AverageScore,
    F.ClosedPostCount,
    CASE 
        WHEN F.ClosedPostCount > 0 AND F.LastClosureDate < NOW() - INTERVAL '1 year' 
        THEN 'Inactivity'
        WHEN F.QuestionCount = 0 AND F.AnswerCount = 0 
        THEN 'Inactive User' 
        ELSE 'Active User'
    END AS UserStatus,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Tags T 
     WHERE T.Count > (SELECT AVG(Count) FROM Tags) 
     AND T.Id IN (SELECT UNNEST(string_to_array(P.Tags, '><'))::int[] 
                  FROM Posts P 
                  WHERE P.OwnerUserId = F.UserId)) AS PopularTags
FROM 
    FinalStats F
ORDER BY 
    F.TotalViews DESC,
    F.UserStatus DESC;



WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(IFF(B.Class = 1, 1, 0)) AS GoldCount,
        SUM(IFF(B.Class = 2, 1, 0)) AS SilverCount,
        SUM(IFF(B.Class = 3, 1, 0)) AS BronzeCount
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
        COUNT(P.Id) AS TotalPosts,
        SUM(IFF(P.PostTypeId = 1, 1, 0)) AS Questions,
        SUM(IFF(P.PostTypeId = 2, 1, 0)) AS Answers,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        CASE 
            WHEN PS.TotalPosts IS NULL THEN 'No Posts'
            WHEN PS.TotalPosts > 100 THEN 'Top Contributor'
            ELSE 'Contributor'
        END AS ContributionLevel
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalBadges,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.AvgScore,
    US.TotalViews,
    US.ContributionLevel,
    COALESCE((
        SELECT LISTAGG(T.TagName, ', ') 
        FROM Tags T 
        JOIN Posts P ON T.ExcerptPostId = P.Id 
        WHERE P.OwnerUserId = US.UserId
    ), 'No Tags') AS AssociatedTags
FROM 
    UserSummary US
ORDER BY 
    US.Reputation DESC, 
    US.TotalPosts DESC
LIMIT 50;

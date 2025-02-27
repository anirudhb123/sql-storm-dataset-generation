WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
),
TopTags AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
    HAVING 
        COUNT(P.Id) > 5
),
ScoreAggregation AS (
    SELECT 
        U.Id AS UserId,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore,
        COUNT(P.Id) AS TotalPosts
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    UB.DisplayName,
    UB.BadgeCount,
    RP.Title,
    RP.ViewCount,
    RP.CommentCount,
    TT.TagName,
    SA.TotalScore,
    SA.AverageScore,
    CASE 
        WHEN SA.TotalScore IS NULL THEN 'No Score Yet'
        WHEN SA.TotalScore > 100 THEN 'High Scorer'
        ELSE 'Needs Improvement'
    END AS ScoreComment
FROM 
    UserBadges UB
JOIN 
    RecentPosts RP ON UB.UserId = RP.OwnerUserId
JOIN 
    TopTags TT ON RP.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' || TT.TagName || '%')
LEFT JOIN 
    ScoreAggregation SA ON UB.UserId = SA.UserId
WHERE 
    RP.PostRank = 1
    AND (RP.ViewCount > 100 OR RP.CommentCount > 10)
ORDER BY 
    UB.BadgeCount DESC, SA.TotalScore DESC
LIMIT 50;

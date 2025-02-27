WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopContributors,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        UserId
),
UserEngagement AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(BC.GoldBadges, 0) AS GoldBadges,
        COALESCE(BC.SilverBadges, 0) AS SilverBadges,
        COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        BadgeCounts BC ON U.Id = BC.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.QuestionCount,
    TS.AnswerCount,
    TS.TotalScore,
    TS.TopContributors,
    TS.AverageViewCount,
    UE.DisplayName AS TopUser,
    UE.GoldBadges,
    UE.SilverBadges,
    UE.BronzeBadges,
    UE.TotalBounty
FROM 
    TagStats TS
JOIN 
    Users U ON TS.TagName = (SELECT T.TagName 
                             FROM Tags T 
                             JOIN Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%') 
                             WHERE P.OwnerUserId = U.Id 
                             ORDER BY P.Score DESC LIMIT 1)
JOIN 
    UserEngagement UE ON U.Id = UE.Id
ORDER BY 
    TS.PostCount DESC, TS.TotalScore DESC
LIMIT 10;

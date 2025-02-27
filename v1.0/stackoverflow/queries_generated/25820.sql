WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore
    FROM 
        Tags 
    LEFT JOIN 
        Posts 
    ON 
        Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS AnswerCount,
        SUM(COALESCE(P.Score, 0)) AS Score
    FROM 
        Users U 
    JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2
    GROUP BY 
        U.Id, U.DisplayName
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
Engagement AS (
    SELECT 
        U.DisplayName,
        MAX(COALESCE(B.BadgeCount, 0)) AS BadgeCount,
        MAX(COALESCE(TS.PostCount, 0)) AS TagCount,
        SUM(COALESCE(TS.TotalViews, 0)) AS TotalViews,
        SUM(COALESCE(TS.TotalScore, 0)) AS TotalScore
    FROM 
        TopUsers U
    LEFT JOIN 
        UserBadges B ON U.UserId = B.UserId
    LEFT JOIN 
        TagStats TS ON U.UserId IN 
        (SELECT DISTINCT U2.Id 
         FROM Users U2 
         JOIN Posts P ON U2.Id = P.OwnerUserId
         JOIN Tags T ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')::int[])
         WHERE P.PostTypeId = 2)
    GROUP BY 
        U.DisplayName
)
SELECT 
    E.DisplayName,
    E.BadgeCount,
    E.TagCount,
    E.TotalViews,
    E.TotalScore
FROM 
    Engagement E
ORDER BY 
    E.TotalScore DESC, 
    E.TotalViews DESC, 
    E.BadgeCount DESC
LIMIT 10;

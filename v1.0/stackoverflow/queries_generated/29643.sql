WITH UniqueTags AS (
    SELECT DISTINCT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName
    FROM 
        Posts
    WHERE
        PostTypeId = 1 -- Only considering questions
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        UniqueTags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
UserTagActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        T.TagName,
        COUNT(DISTINCT P.Id) AS QuestionsWithTag,
        SUM(P.ViewCount) AS TagViews
    FROM
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    JOIN 
        UniqueTags T ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        U.Id, U.DisplayName, T.TagName
)
SELECT 
    U.DisplayName,
    U.QuestionCount,
    U.CommentCount,
    U.BadgeCount,
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.AverageScore,
    UTA.QuestionsWithTag,
    UTA.TagViews
FROM 
    UserActivity U
LEFT JOIN 
    TagStatistics T ON TRUE
LEFT JOIN 
    UserTagActivity UTA ON U.Id = UTA.UserId AND T.TagName = UTA.TagName
ORDER BY 
    U.QuestionCount DESC, T.TotalViews DESC, U.DisplayName;

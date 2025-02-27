WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 3 WHEN B.Class = 2 THEN 2 WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BadgeScore,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Only questions
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        BadgeScore DESC, TotalScore DESC
    LIMIT 5
),
ActiveTags AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(P.Id) AS QuestionCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%') AND P.PostTypeId = 1 -- Only questions
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10 -- At least 10 questions with the tag
)
SELECT 
    T.TagName,
    TC.PostCount,
    AU.DisplayName AS TopUser,
    AU.BadgeScore,
    AT.TotalViews,
    AT.QuestionCount AS ActiveQuestionCount
FROM 
    TagCounts TC
JOIN 
    ActiveTags AT ON TC.TagName = AT.TagName
JOIN 
    TopUsers AU ON TC.PostCount = (
        SELECT MAX(PostCount)
        FROM TagCounts
    )
WHERE 
    TC.PostCount > 5 -- Only consider tags linked to more than 5 questions
ORDER BY 
    TC.PostCount DESC, AT.TotalViews DESC;

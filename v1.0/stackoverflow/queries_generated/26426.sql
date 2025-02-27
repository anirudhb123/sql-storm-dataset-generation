WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AvgScore
    FROM 
        Posts
    GROUP BY 
        TagName
),

UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(B.Class, 0)) AS TotalClass, 
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

MostActiveUsers AS (
    SELECT 
        P.OwnerUserId,
        U.DisplayName,
        COUNT(*) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.OwnerUserId, U.DisplayName
)

SELECT 
    TS.TagName,
    TS.PostCount,
    TS.QuestionCount,
    TS.AnswerCount,
    TS.TotalViews,
    TS.AvgScore,
    U.UserId,
    U.DisplayName AS UserName,
    U.AvgReputation,
    MU.PostCount AS UserPostCount,
    MU.TotalViews AS UserTotalViews
FROM 
    TagStats TS
JOIN 
    UserReputation U ON U.TotalClass >= 3 
JOIN 
    MostActiveUsers MU ON MU.OwnerUserId = U.UserId
WHERE 
    TS.PostCount > 5
ORDER BY 
    TS.TotalViews DESC, U.AvgReputation DESC;


WITH RecursiveTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        value AS TagName,
        P.CreationDate
    FROM 
        Posts P
    CROSS APPLY STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '><') AS T(value)
    WHERE 
        P.PostTypeId = 1
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(PostId) AS PostCount,
        MIN(CreationDate) AS FirstUsage
    FROM 
        RecursiveTags
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        FirstUsage
    FROM 
        TagCounts
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId IN (1, 2)
    GROUP BY 
        U.Id, U.DisplayName
),
UserTopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        PositiveScoreCount
    FROM 
        UserPostCounts
    WHERE 
        PostCount > 0
    ORDER BY 
        PositiveScoreCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
),
FinalOutput AS (
    SELECT 
        T.TagName,
        T.PostCount AS TagPostCount,
        U.DisplayName AS TopUser,
        U.PositiveScoreCount AS TopUserScores
    FROM 
        TopTags T
    JOIN 
        UserTopContributors U ON U.PostCount > T.PostCount
)
SELECT 
    TagName, 
    TagPostCount, 
    TopUser, 
    TopUserScores
FROM 
    FinalOutput
ORDER BY 
    TagPostCount DESC, 
    TopUserScores DESC;


WITH TagStats AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(value)
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        SUM(ISNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
    WHERE 
        PostCount > 5  
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AcceptedAnswerCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY QuestionCount DESC, TotalScore DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.QuestionCount,
    TU.AcceptedAnswerCount,
    TU.TotalViews,
    TU.TotalScore,
    TT.TagName AS PopularTag,
    TT.PostCount
FROM 
    TopUsers TU
JOIN 
    TopTags TT ON TU.QuestionCount > 10  
WHERE 
    TU.UserRank <= 10 AND TT.TagRank <= 20  
ORDER BY 
    TU.TotalScore DESC, TU.AcceptedAnswerCount DESC;

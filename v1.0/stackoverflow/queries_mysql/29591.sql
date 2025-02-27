
WITH TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore
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
        @rank := IF(@prevCount = PostCount, @rank, @rank + 1) AS TagRank,
        @prevCount := PostCount
    FROM 
        TagStats, (SELECT @rank := 0, @prevCount := NULL) AS vars
    WHERE 
        PostCount > 5  
    ORDER BY 
        PostCount DESC
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AcceptedAnswerCount,
        TotalViews,
        TotalScore,
        @userRank := IF(@prevUserCount = QuestionCount AND @prevUserScore = TotalScore, @userRank, @userRank + 1) AS UserRank,
        @prevUserCount := QuestionCount,
        @prevUserScore := TotalScore
    FROM 
        UserPostStats, (SELECT @userRank := 0, @prevUserCount := NULL, @prevUserScore := NULL) AS userVars
    ORDER BY 
        QuestionCount DESC, TotalScore DESC
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

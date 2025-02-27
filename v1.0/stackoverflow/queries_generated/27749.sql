WITH TagCounts AS (
    SELECT 
        T.TagName, 
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, '> <')::int[])
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount, 
        TotalViews, 
        TotalAnswers,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS AnswerRank
    FROM 
        TagCounts
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.OwnerUserId = U.Id THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN A.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Posts A ON A.AcceptedAnswerId = P.Id
    GROUP BY 
        U.Id
),
PopularUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalScore,
        TotalAnswers,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserReputation
    WHERE 
        TotalScore > 0
)
SELECT 
    TT.TagName,
    TT.PostCount,
    TT.TotalViews,
    TT.TotalAnswers,
    PU.DisplayName AS PopularUser,
    PU.TotalScore,
    PU.TotalAnswers AS UserAnswers,
    TT.ViewRank,
    TT.AnswerRank,
    PU.ScoreRank
FROM 
    TopTags TT
JOIN 
    PopularUsers PU ON TT.TotalAnswers > 0
WHERE 
    TT.ViewRank <= 10 AND PU.ScoreRank <= 10
ORDER BY 
    TT.TotalViews DESC, PU.TotalScore DESC;

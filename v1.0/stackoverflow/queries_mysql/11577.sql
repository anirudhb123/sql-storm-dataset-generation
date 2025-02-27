
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageScore,
        TotalViews,
        LastPostDate,
        @user_rank := @user_rank + 1 AS Rank
    FROM 
        UserStats, (SELECT @user_rank := 0) AS r
    ORDER BY 
        Reputation DESC
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        @tag_rank := @tag_rank + 1 AS Rank
    FROM 
        TagStats, (SELECT @tag_rank := 0) AS r
    ORDER BY 
        PostCount DESC
)
SELECT 
    TU.UserId, 
    TU.Reputation, 
    TU.PostCount, 
    TU.QuestionCount, 
    TU.AnswerCount, 
    TU.AverageScore, 
    TU.TotalViews, 
    TU.LastPostDate, 
    TT.TagName, 
    TT.PostCount AS TagPostCount, 
    TT.TotalViews AS TagTotalViews
FROM 
    TopUsers TU
JOIN 
    TopTags TT ON TU.Rank = TT.Rank
WHERE 
    TU.Rank <= 10 AND TT.Rank <= 10
ORDER BY 
    TU.Rank, TT.Rank;

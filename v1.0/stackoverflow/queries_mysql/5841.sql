
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        AvgScore,
        TotalViews,
        @rownum := @rownum + 1 AS Rnk
    FROM 
        UserStats, (SELECT @rownum := 0) r
    ORDER BY 
        Reputation DESC, PostCount DESC, AvgScore DESC
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', numbers.n), '<>', -1) AS Tag
    FROM 
        Posts P
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '<>', '')) >= numbers.n - 1
    WHERE 
        P.Tags IS NOT NULL
),
TagStats AS (
    SELECT 
        T.Tag AS TagName,
        COUNT(DISTINCT T.PostId) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        PostTags T
    JOIN 
        Posts P ON T.PostId = P.Id
    GROUP BY 
        T.Tag
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        @tagrownum := @tagrownum + 1 AS Rnk
    FROM 
        TagStats, (SELECT @tagrownum := 0) r
    ORDER BY 
        PostCount DESC, TotalViews DESC
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.PostCount,
    U.AnswerCount,
    U.QuestionCount,
    U.AvgScore,
    U.TotalViews,
    T.TagName,
    T.PostCount AS TagPostCount,
    T.TotalViews AS TagTotalViews
FROM 
    TopUsers U
JOIN 
    TopTags T ON U.Rnk <= 10 AND T.Rnk <= 10
ORDER BY 
    U.Reputation DESC, U.PostCount DESC, T.PostCount DESC;

WITH TagFrequency AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only considering questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagFrequency
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000 -- Active users with good reputation
    GROUP BY 
        U.Id, U.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS UserRank
    FROM 
        ActiveUsers
)

SELECT 
    TT.Tag,
    TT.TagCount,
    TA.DisplayName AS TopUser,
    TA.TotalViews,
    TA.QuestionCount,
    TA.AnswerCount
FROM 
    TopTags TT
JOIN 
    TopActiveUsers TA ON TA.QuestionCount > 0 -- Ensuring Top Users have asked at least one question
WHERE 
    TT.Rank <= 10 -- Selecting top 10 tags
ORDER BY 
    TT.TagCount DESC, TA.TotalViews DESC;

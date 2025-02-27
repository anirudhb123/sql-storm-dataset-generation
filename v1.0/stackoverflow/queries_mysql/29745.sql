
WITH TagFrequency AS (
    SELECT 
        TRIM(UNNEST(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', -1), '>', 1))) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagFrequency, (SELECT @rank := 0) r
    ORDER BY 
        TagCount DESC
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000 
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
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        ActiveUsers, (SELECT @user_rank := 0) r
    ORDER BY 
        TotalViews DESC
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
    TopActiveUsers TA ON TA.QuestionCount > 0 
WHERE 
    TT.Rank <= 10 
ORDER BY 
    TT.TagCount DESC, TA.TotalViews DESC;

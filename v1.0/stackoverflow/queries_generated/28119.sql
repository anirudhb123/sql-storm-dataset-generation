WITH TagCount AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only consider Questions
    GROUP BY 
        TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(CAST(P.Score AS INT)), 0) AS TotalScore,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts P ON u.Id = P.OwnerUserId AND P.PostTypeId = 1  -- Questions authored by user
    LEFT JOIN 
        Comments C ON C.UserId = u.Id  -- Comments by user
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount
    FROM 
        TagCount
    ORDER BY 
        PostCount DESC
    LIMIT 10  -- Top 10 tags
),
DetailedUserActivity AS (
    SELECT 
        ua.DisplayName,
        ua.TotalViews,
        ua.TotalScore,
        ua.QuestionCount,
        ua.CommentCount,
        tt.TagName
    FROM 
        UserActivity ua
    JOIN 
        Posts p ON ua.UserId = p.OwnerUserId AND p.PostTypeId = 1  -- Only consider Questions authored by users
    JOIN 
        TagCount tc ON tc.PostCount = (
            SELECT MAX(PostCount) FROM TagCount
        ) AND tc.TagName IN (SELECT TagName FROM TopTags)
    WHERE 
        ua.QuestionCount > 0
)
SELECT 
    DisplayName,
    TotalViews,
    TotalScore,
    QuestionCount,
    CommentCount,
    STRING_AGG(TagName, ', ') AS TopTags
FROM 
    DetailedUserActivity
GROUP BY 
    DisplayName, TotalViews, TotalScore, QuestionCount, CommentCount
ORDER BY 
    TotalScore DESC, TotalViews DESC;

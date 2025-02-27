
WITH TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        PostsCount DESC
    LIMIT 5
),
TopTags AS (
    SELECT 
        TF.TagName,
        TF.PostCount,
        RANK() OVER (ORDER BY TF.PostCount DESC) AS Rank
    FROM 
        TagFrequency TF
    WHERE 
        TF.PostCount > 10
),
TagUsers AS (
    SELECT 
        T.TagName,
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS UserPostsCount
    FROM 
        Tags T
    JOIN 
        Posts P ON LOCATE(CONCAT('<', T.TagName, '>'), P.Tags) > 0
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName, U.Id, U.DisplayName
)
SELECT 
    T.TagName,
    T.PostCount,
    A.DisplayName AS ActiveUser,
    A.PostsCount,
    A.TotalViews,
    A.TotalScore,
    COUNT(DISTINCT U.UserId) AS ContributorsCount,
    COALESCE(AVG(UserPostsCount), 0) AS AvgUserPostsCount
FROM 
    TopTags T
JOIN 
    MostActiveUsers A ON A.PostsCount > 0
LEFT JOIN 
    TagUsers U ON U.TagName = T.TagName
GROUP BY 
    T.TagName, T.PostCount, A.DisplayName, A.PostsCount, A.TotalViews, A.TotalScore
ORDER BY 
    T.PostCount DESC;


WITH TagFrequency AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        LATERAL SPLIT_TO_TABLE(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><') AS value
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(value)
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
        P.CreationDate >= DATEADD(year, -1, '2024-10-01')
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
        Posts P ON POSITION('<' || T.TagName || '>' IN P.Tags) > 0
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

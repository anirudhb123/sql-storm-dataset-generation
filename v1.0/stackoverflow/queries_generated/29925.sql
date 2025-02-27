WITH TagStatistics AS (
    SELECT 
        Tags.Id AS TagId,
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        AVG(COALESCE(Posts.Score, 0)) AS AverageScore
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    GROUP BY 
        Tags.Id, Tags.TagName
),
ActiveUsers AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS Contributions,
        SUM(Posts.Score) AS ContributionScore
    FROM 
        Users
    INNER JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Users.Id, Users.DisplayName
),
TopPosts AS (
    SELECT 
        Posts.Id,
        Posts.Title,
        Posts.Score,
        Users.DisplayName AS OwnerDisplayName,
        Tags.TagName,
        Posts.CreationDate
    FROM 
        Posts
    INNER JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Tags ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    WHERE 
        Posts.Score >= 10 AND 
        Posts.CreationDate >= NOW() - INTERVAL '1 month'
    ORDER BY 
        Posts.Score DESC
    LIMIT 10
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.TotalScore,
    T.AverageScore,
    U.DisplayName AS ActiveUser,
    U.Contributions,
    U.ContributionScore,
    P.Title AS TopPostTitle,
    P.OwnerDisplayName,
    P.Score AS TopPostScore,
    P.CreationDate AS TopPostDate
FROM 
    TagStatistics T
LEFT JOIN 
    ActiveUsers U ON U.Contributions > 5
LEFT JOIN 
    TopPosts P ON P.TagName = T.TagName
ORDER BY 
    T.TotalViews DESC, 
    U.ContributionScore DESC, 
    P.Score DESC;

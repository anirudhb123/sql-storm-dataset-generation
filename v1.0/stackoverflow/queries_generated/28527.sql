WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopUsers
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        T.TagName
),
TopTagStats AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.AverageScore,
    T.TopUsers
FROM 
    TopTagStats T
WHERE 
    T.TagRank <= 10
ORDER BY 
    T.TagRank;
This SQL query computes the statistics of the top 10 tags based on the number of posts created in the last year. It aggregates post views, calculates the average score of the posts, and concatenates the display names of the users who created the posts associated with each tag. The results are ordered by the rank of the tags.

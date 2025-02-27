WITH Benchmark AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(C.Comment) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM
        Posts AS P
    LEFT JOIN
        Users AS U ON P.OwnerUserId = U.Id
    LEFT JOIN
        Comments AS C ON P.Id = C.PostId
    LEFT JOIN
        Votes AS V ON P.Id = V.PostId
    WHERE
        P.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
    GROUP BY
        P.Id, U.DisplayName
),
PerformanceMetrics AS (
    SELECT
        COUNT(PostId) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        SUM(CommentCount) AS TotalComments,
        SUM(VoteCount) AS TotalVotes
    FROM
        Benchmark
)
SELECT
    TotalPosts,
    AvgViewCount,
    AvgScore,
    TotalComments,
    TotalVotes
FROM
    PerformanceMetrics;

-- Performance benchmarking SQL query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        COALESCE(SUM(B.Reputation), 0) AS TotalAuthorReputation,
        COALESCE(MAX(B.CreatedAt), '1970-01-01') AS LatestBadgeDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount
),
AggregatedStats AS (
    SELECT 
        PostTypeId,
        COUNT(PostId) AS PostCount,
        AVG(Score) AS AvgScore,
        SUM(ViewCount) AS TotalViews,
        SUM(CommentCount) AS TotalComments,
        SUM(VoteCount) AS TotalVotes,
        AVG(TotalAuthorReputation) AS AvgAuthorReputation,
        MAX(LatestBadgeDate) AS LatestBadgeDate
    FROM 
        PostStats
    GROUP BY 
        PostTypeId
)
SELECT 
    PT.Name AS PostType,
    AS.PostCount,
    AS.AvgScore,
    AS.TotalViews,
    AS.TotalComments,
    AS.TotalVotes,
    AS.AvgAuthorReputation,
    AS.LatestBadgeDate
FROM 
    AggregatedStats AS AS
JOIN 
    PostTypes PT ON AS.PostTypeId = PT.Id
ORDER BY 
    AS.PostCount DESC;

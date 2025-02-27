-- Performance Benchmarking Query
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(C.CreationDate, 0)) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        COUNT(DISTINCT P.OwnerUserId) AS UniqueUsers
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
VoteSummary AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.Questions,
    UA.Answers,
    UA.PositivePosts,
    UA.NegativePosts,
    UA.CommentCount,
    TS.TagName,
    TS.PostCount AS TagPostCount,
    TS.TotalViews,
    TS.AverageScore,
    TS.UniqueUsers,
    VS.UpVotes,
    VS.DownVotes,
    VS.CloseVotes
FROM 
    UserActivity UA
LEFT JOIN 
    TagStatistics TS ON UA.PostCount > 0
LEFT JOIN 
    VoteSummary VS ON UA.PostCount > 0
ORDER BY 
    UA.PostCount DESC;

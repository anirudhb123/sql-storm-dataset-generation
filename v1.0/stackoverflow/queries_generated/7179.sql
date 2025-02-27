WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(PS.TotalVotes, 0) AS TotalVotes,
        COALESCE(PS.UpVotes, 0) AS UpVotes,
        COALESCE(PS.DownVotes, 0) AS DownVotes
    FROM Posts P
    LEFT JOIN UserVoteStats PS ON P.OwnerUserId = PS.UserId
),
TagStatistics AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.Id, T.TagName
),
FinalResults AS (
    SELECT 
        P.Title,
        P.Score,
        P.ViewCount,
        PS.TotalVotes,
        PS.UpVotes,
        PS.DownVotes,
        TS.TagName,
        TS.PostCount,
        TS.TotalViews,
        TS.AverageScore
    FROM PostStatDetails P
    JOIN TagStatistics TS ON TS.PostCount > 0
)
SELECT 
    Title,
    Score,
    ViewCount,
    TotalVotes,
    UpVotes,
    DownVotes,
    TagName,
    PostCount,
    TotalViews,
    AverageScore
FROM FinalResults
ORDER BY TotalVotes DESC, Score DESC
LIMIT 100;

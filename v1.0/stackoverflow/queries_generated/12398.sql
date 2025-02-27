-- Performance Benchmarking Query
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(V.VoteTypeId IN (2), 0)) AS UpVotes,
        SUM(COALESCE(V.VoteTypeId IN (3), 0)) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
),
TagStatistics AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.Id, T.TagName
)
SELECT 
    US.UserId,
    US.Reputation,
    US.PostCount,
    US.BadgeCount,
    US.UpVotes,
    US.DownVotes,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    PS.OwnerDisplayName,
    PS.OwnerReputation,
    TS.TagId,
    TS.TagName,
    TS.TotalViews,
    TS.PostCount AS TagPostCount
FROM UserStatistics US
JOIN PostStatistics PS ON US.UserId = PS.OwnerDisplayName
JOIN TagStatistics TS ON PS.Title LIKE '%' || TS.TagName || '%'
ORDER BY US.Reputation DESC, PS.ViewCount DESC;

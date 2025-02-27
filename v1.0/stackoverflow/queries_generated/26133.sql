WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(P.ViewCount) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        BadgeCount,
        TotalUpVotes,
        TotalDownVotes,
        CommentCount,
        TotalViews,
        DENSE_RANK() OVER (ORDER BY Reputation DESC, PostCount DESC, TotalUpVotes DESC) AS Rank
    FROM UserMetrics
),
BestTagQuestions AS (
    SELECT 
        T.TagName,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1 -- Questions only
    GROUP BY T.TagName, P.Id 
    HAVING COUNT(DISTINCT V.Id) > 10 -- More than 10 votes
    ORDER BY SUM(P.ViewCount) DESC
),
UserInteraction AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.BadgeCount,
    TU.TotalUpVotes,
    TU.TotalDownVotes,
    TU.CommentCount,
    TU.TotalViews,
    BQ.TagName AS BestTag,
    BQ.Title AS TopQuestion,
    BQ.Score AS QuestionScore,
    BQ.ViewCount AS QuestionViews,
    UI.CommentCount AS UserCommentCount,
    UI.VoteCount AS UserVoteCount,
    UI.UpVotes AS UserUpVotes,
    UI.DownVotes AS UserDownVotes
FROM TopUsers TU
JOIN BestTagQuestions BQ ON TU.UserId = BQ.UserId
JOIN UserInteraction UI ON TU.UserId = UI.UserId
WHERE TU.Rank <= 10
ORDER BY TU.Rank;

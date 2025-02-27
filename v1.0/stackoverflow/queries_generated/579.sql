WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.ViewCount DESC) AS RankViewCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= '2022-01-01'
    GROUP BY P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseReasonCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    PS.Title,
    PS.UpvoteCount,
    PS.DownvoteCount,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    COALESCE(CP.CloseReasonCount, 0) AS PostClosedCount,
    RANK() OVER (PARTITION BY U.Id ORDER BY PS.ViewCount DESC) AS UserPostRank
FROM UserVoteSummary U
JOIN PostSummary PS ON PS.UpvoteCount > 5
LEFT JOIN ClosedPosts CP ON PS.PostId = CP.PostId
WHERE U.TotalVotes > 10
ORDER BY PS.UpvoteCount DESC, U.DisplayName ASC;

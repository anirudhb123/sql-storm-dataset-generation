WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(CASE WHEN PH.Id IS NOT NULL THEN 1 END) AS TotalHistoryEntries
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        TotalComments,
        TotalHistoryEntries,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank
    FROM PostStats
)
SELECT 
    U.DisplayName,
    UPS.TotalVotes,
    UPS.Upvotes,
    UPS.Downvotes,
    TP.Title,
    TP.TotalComments,
    TP.TotalHistoryEntries
FROM UserVoteStats UPS
JOIN TopPosts TP ON UPS.TotalVotes > 10  -- Only consider users with significant votes
WHERE TP.CommentRank <= 5  -- Select top 5 posts by comments
ORDER BY UPS.TotalVotes DESC, TP.TotalComments DESC;

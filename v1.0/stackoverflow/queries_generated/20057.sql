WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount,
        MAX(PH.CreationDate) AS LastCloseDate,
        STRING_AGG(CASE WHEN PH.UserId IS NOT NULL THEN PH.UserDisplayName END, ', ') AS Closers
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY P.Id, P.Title
),
TopClosedPosts AS (
    SELECT 
        CP.PostId,
        CP.Title,
        CP.CloseVoteCount,
        CP.LastCloseDate,
        CP.Closers,
        ROW_NUMBER() OVER (ORDER BY CP.CloseVoteCount DESC, CP.LastCloseDate ASC) AS Rank
    FROM ClosedPosts CP
    WHERE CP.CloseVoteCount > 0
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        (P.ViewCount + COALESCE((SELECT SUM(V.BountyAmount) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId IN (8, 9)), 0)) AS EngagementScore,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year' 
      AND P.Score IS NOT NULL
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.EngagementScore,
    PS.OwnerDisplayName,
    TCP.CloseVoteCount,
    TCP.LastCloseDate,
    TCP.Closers,
    UVC.VoteCount AS UserVoteCount,
    UVC.UpVoteCount,
    UVC.DownVoteCount
FROM PostStats PS
LEFT JOIN TopClosedPosts TCP ON PS.PostId = TCP.PostId
LEFT JOIN UserVoteCounts UVC ON PS.OwnerDisplayName = UVC.DisplayName
WHERE PS.EngagementScore >= (SELECT AVG(EngagementScore) FROM PostStats)
  AND TCP.Rank <= 10
ORDER BY PS.EngagementScore DESC, PS.CreationDate ASC
OPTION (RECOMPILE);

### Explanation of the Query:

1. **UserVoteCounts CTE**: Aggregates vote counts for users, counting both upvotes and downvotes.
2. **ClosedPosts CTE**: Gathers statistics for posts that have been closed, counting close votes, and capturing the last close date and the usernames of the users who closed them.
3. **TopClosedPosts CTE**: Filters and ranks closed posts based on the number of close votes, focusing only on posts that have been closed at least once.
4. **PostStats CTE**: Calculates an engagement score for posts based on their view counts and any bounty amounts associated with them, also retrieving the owner's display name.
5. **Final SELECT**: Combines all the CTEs to output relevant post data, including engagement scores, closure stats, and vote counts while applying filters to focus on posts with above-average engagement scores, limiting to the top 10 closed posts, and ordering the results.
6. **OPTION (RECOMPILE)**: Forces a recompilation of the execution plan for this query every time it's run, optimizing performance based on the current data set.

This SQL query demonstrates multiple complex constructs, including multiple CTEs, window functions, and outer joins, while also exploring NULL handling via left joins and subqueries.

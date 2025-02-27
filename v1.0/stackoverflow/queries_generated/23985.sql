WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT CASE WHEN V.VoteTypeId IN (2, 3) THEN V.PostId END) AS TotalVotedPosts
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostActivity AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.Comment IS NOT NULL THEN 1 END), 0) AS HistoryEntryCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score
),
TopPosts AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.ViewCount,
        PA.Score,
        RANK() OVER (ORDER BY PA.Score DESC, PA.ViewCount DESC) AS PostRank
    FROM PostActivity PA
    WHERE PA.Score > 0
)
SELECT 
    U.DisplayName,
    UVs.UpVotes,
    UVs.DownVotes,
    TP.Title,
    TP.ViewCount,
    TP.Score,
    TP.PostRank,
    CASE 
        WHEN UVs.TotalVotedPosts > 0 THEN 'Active Voter'
        ELSE 'Inactive Voter'
    END AS VotingStatus
FROM UserVoteStats UVs
JOIN TopPosts TP ON UVs.UserId = TP.PostId
WHERE UVs.UpVotes - UVs.DownVotes > 0
AND TP.PostRank <= 10
ORDER BY TP.Score DESC, UVs.UpVotes DESC;

This SQL query accomplishes several tasks:

1. **Common Table Expressions (CTEs)**: 
   - `UserVoteStats` counts upvotes and downvotes for each user and calculates the total number of posts they voted on.
   - `PostActivity` gathers statistical data about each post, including view count, total score, and the number of comments and post history entries associated with it.
   - `TopPosts` ranks posts based on their score and view count.

2. **Correlated Subqueries**: Not directly used, but integrated through aggregates and joins.

3. **Window Functions**: RANK() is used to rank posts based on score and view count.

4. **Complex Predicates**: The final selection combines multiple conditions related to user voting behavior and post characteristics.

5. **NULL Logic**: Uses COALESCE to handle potential NULL values while counting comments and history entries.

6. **String Expressions and Calculations**: Displays user and post details concisely while calculating distinct counts.

7. **Bizarre SQL Semantics**: The logic of identifying "Active Voter" versus "Inactive Voter" based on the net vote count could be considered an obscure corner case.

This overall structure provides a rich dataset for performance benchmarking, showcasing various SQL constructs efficiently.

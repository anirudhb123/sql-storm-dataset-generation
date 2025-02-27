WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation >= 0
    GROUP BY U.Id
),
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 1 THEN PH.CreationDate END) AS InitialTitleDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 2 THEN PH.CreationDate END) AS InitialBodyDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS ClosedDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditsCount
    FROM PostHistory PH
    GROUP BY PH.PostId
),
RecentPostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(COUNT(C.Id), 0) AS CommentsCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY P.Id
),
FinalResults AS (
    SELECT 
        U.DisplayName,
        U.UserRank,
        RPT.PostId,
        RPT.Title,
        RPT.CreationDate,
        COALESCE(PHA.EditsCount, 0) AS EditsCount,
        COALESCE(PHA.ClosedDate, 'No Closure') AS PostStatus,
        RPT.CommentsCount,
        (U.TotalUpVotes - U.TotalDownVotes) AS NetVotes,
        CASE 
            WHEN (U.TotalUpVotes - U.TotalDownVotes) > 0 THEN 'Positive'
            WHEN (U.TotalUpVotes - U.TotalDownVotes) < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSummary
    FROM UserStats U
    INNER JOIN RecentPostsWithComments RPT ON U.TotalPosts > 0
    LEFT JOIN PostHistoryAnalysis PHA ON PHA.PostId = RPT.PostId
    WHERE U.UserRank < 50 OR RPT.CommentsCount > 5
)
SELECT 
    FR.DisplayName,
    FR.PostId,
    FR.Title,
    FR.CreationDate,
    FR.EditsCount,
    FR.PostStatus,
    FR.CommentsCount,
    FR.NetVotes,
    FR.VoteSummary
FROM FinalResults FR
WHERE FR.EditsCount > 0 OR FR.PostStatus != 'No Closure'
ORDER BY FR.NetVotes DESC, FR.CreationDate DESC;

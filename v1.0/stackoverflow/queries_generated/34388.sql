WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, CreationDate, Location,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopUsers AS (
    SELECT Id, DisplayName, Reputation
    FROM Users
    WHERE Reputation > 1000
    ORDER BY Reputation DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT P.Id AS PostId, 
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.Id
),
TopPosts AS (
    SELECT PS.PostId, PS.UpVotes, PS.DownVotes, PS.CommentCount, PS.AvgScore,
           ROW_NUMBER() OVER (ORDER BY PS.AvgScore DESC) AS PostRank
    FROM PostStatistics PS
    WHERE PS.AvgScore > 0
),
ClosedPosts AS (
    SELECT PH.PostId, PH.CreationDate, P.Title, P.Body
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10 -- Closed posts
    AND PH.CreationDate >= NOW() - INTERVAL '1 month'
),
ClosedPostsDetail AS (
    SELECT CP.PostId, CP.CreationDate, CP.Title,
           CASE WHEN CP.CreationDate < NOW() - INTERVAL '1 week' THEN 'Closed more than a week ago'
                ELSE 'Recently Closed' END AS ClosureRecent,
           COUNT(PC.PostId) AS RelatedClosedCount
    FROM ClosedPosts CP
    LEFT JOIN PostLinks PL ON CP.PostId = PL.PostId
    LEFT JOIN ClosedPosts CP2 ON PL.RelatedPostId = CP2.PostId
    GROUP BY CP.PostId, CP.CreationDate, CP.Title
)
SELECT U.DisplayName, U.Reputation, T.PostId, T.UpVotes, T.DownVotes, T.CommentCount, T.AvgScore,
       C.Title AS ClosedPostTitle, C.CreationDate AS ClosedDate,
       COALESCE(CC.RelatedClosedCount, 0) AS RelatedClosedPosts
FROM TopUsers U
JOIN TopPosts T ON T.CommentCount > 5
LEFT JOIN ClosedPostsDetail C ON T.PostId = C.PostId
LEFT JOIN (
    SELECT PostId, COUNT(DISTINCT RelatedPostId) AS RelatedClosedCount
    FROM PostLinks
    WHERE LinkTypeId = 3 -- Duplicate links
    GROUP BY PostId
) CC ON C.PostId = CC.PostId
ORDER BY U.Reputation DESC, T.AvgScore DESC;

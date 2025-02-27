WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
TagPopularity AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        STRING_AGG(DISTINCT U.DisplayName, ', ' ORDER BY U.Reputation DESC) AS TopUsers
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    JOIN Users U ON P.OwnerUserId = U.Id
    GROUP BY T.TagName
    HAVING COUNT(DISTINCT P.Id) > 0
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PT.Name AS PostType,
        U.DisplayName AS ClosedBy,
        PH.Comment AS CloseReason
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN Users U ON PH.UserId = U.Id
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    WHERE PHT.Name = 'Post Closed'
    ORDER BY PH.CreationDate DESC
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        AVG(VoteCount) AS AverageRating
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY P.Id, P.Title
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    COALESCE(TP.TagName, 'No Tags') AS PopularTag,
    COALESCE(TP.PostCount, 0) AS PopularTagPostCount,
    PH.PostId AS ClosedPostId,
    PH.CreationDate AS ClosedDate,
    PH.PostType,
    PH.ClosedBy,
    PH.CloseReason,
    PS.Title,
    PS.TotalComments,
    PS.AverageRating,
    CASE 
        WHEN PS.AverageRating IS NULL THEN 'No Ratings Yet'
        WHEN PS.AverageRating > 5 THEN 'Highly Rated'
        ELSE 'Average Rated'
    END AS RatingStatus
FROM UserVoteSummary U
LEFT JOIN TagPopularity TP ON U.TotalPosts = (
    SELECT MAX(TotalPosts) FROM UserVoteSummary
)
LEFT JOIN ClosedPostHistory PH ON U.UserId = PH.ClosedBy
LEFT JOIN PostStatistics PS ON PH.PostId = PS.PostId
ORDER BY U.TotalPosts DESC, PS.AverageRating DESC
LIMIT 100;

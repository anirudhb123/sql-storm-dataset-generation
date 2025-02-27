-- Performance Benchmarking SQL Query

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPostHistory AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        PH.UserId AS EditorUserId,
        PH.CreationDate AS EditDate,
        PH.Comment,
        RANK() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditRank
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalScore,
    UA.TotalViews,
    UA.TotalComments,
    UA.TotalBadges,
    RPH.PostId,
    RPH.EditorUserId,
    RPH.EditDate,
    RPH.Comment
FROM UserActivity UA
LEFT JOIN RecentPostHistory RPH ON UA.UserId = RPH.OwnerUserId
WHERE RPH.EditRank = 1 -- Get only the most recent edit per post
ORDER BY UA.TotalScore DESC, UA.TotalPosts DESC;

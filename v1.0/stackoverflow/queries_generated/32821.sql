WITH RECURSIVE UserVoteCounts AS (
    SELECT
        U.Id AS UserId,
        COUNT(V.Id) AS VoteCount
    FROM
        Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY
        U.Id
),
PostRecentEdit AS (
    SELECT
        P.Id AS PostId,
        MAX(PH.CreationDate) AS LastEditDate
    FROM
        Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE
        PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    GROUP BY
        P.Id
),
UserPostActivity AS (
    SELECT
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id
),
ActivePosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(UP.PostsCreated, 0) AS PostsCreated,
        COALESCE(UP.TotalViews, 0) AS TotalViews,
        COALESCE(UP.TotalAnswers, 0) AS TotalAnswers,
        RANK() OVER (ORDER BY P.CreationDate DESC) AS RecentRank
    FROM
        Posts P
    LEFT JOIN UserPostActivity UP ON P.OwnerUserId = UP.UserId
    WHERE
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostSummary AS (
    SELECT
        AP.PostId,
        AP.Title,
        AP.CreationDate,
        AP.Score,
        AP.TotalViews,
        AP.TotalAnswers,
        PH.LastEditDate,
        U.DisplayName AS OwnerDisplayName,
        UC.VoteCount AS UserVoteCount
    FROM
        ActivePosts AP
    LEFT JOIN PostRecentEdit PH ON AP.PostId = PH.PostId
    LEFT JOIN Users U ON AP.OwnerUserId = U.Id
    LEFT JOIN UserVoteCounts UC ON U.Id = UC.UserId
)
SELECT
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.TotalViews,
    PS.TotalAnswers,
    PS.LastEditDate,
    PS.OwnerDisplayName,
    PS.UserVoteCount,
    CASE
        WHEN PS.TotalAnswers > 5 THEN 'Highly Answered'
        WHEN PS.TotalAnswers BETWEEN 1 AND 5 THEN 'Moderately Answered'
        ELSE 'No Answers'
    END AS AnswerCategory
FROM
    PostSummary PS
WHERE
    PS.UserVoteCount IS NOT NULL
ORDER BY
    PS.Score DESC, PS.CreationDate DESC
LIMIT 100;

WITH RecursivePosts AS (
    SELECT
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        P.CreationDate,
        0 AS Level
    FROM
        Posts P
    WHERE
        P.ParentId IS NULL -- Top-level posts (Questions)
    UNION ALL
    SELECT
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        P.CreationDate,
        Level + 1
    FROM
        Posts P
    INNER JOIN RecursivePosts RP ON
        P.ParentId = RP.Id -- Join child posts (Answers) to their parent questions
),
UserScores AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(P.Score) AS AvgPostScore
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
PostHistoryAggregates AS (
    SELECT
        PH.UserId,
        COUNT(PH.Id) AS HistoryCount,
        COUNT(DISTINCT PH.PostId) AS UniquePostsEdited,
        MAX(PH.CreationDate) AS LastEditDate
    FROM
        PostHistory PH
    WHERE
        PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY
        PH.UserId
),
AggregatedData AS (
    SELECT
        U.DisplayName,
        U.TotalScore,
        U.TotalPosts,
        U.TotalComments,
        U.AvgPostScore,
        COALESCE(PH.HistoryCount, 0) AS EditHistoryCount,
        COALESCE(PH.UniquePostsEdited, 0) AS UniquePostsEdited,
        COALESCE(PH.LastEditDate, '1970-01-01') AS LastEditDate
    FROM
        UserScores U
    LEFT JOIN
        PostHistoryAggregates PH ON U.UserId = PH.UserId
)
SELECT
    AD.DisplayName,
    AD.TotalScore,
    AD.TotalPosts,
    AD.TotalComments,
    AD.AvgPostScore,
    AD.EditHistoryCount,
    AD.UniquePostsEdited,
    AD.LastEditDate,
    COUNT(DISTINCT (CASE WHEN RP.Level = 0 THEN RP.Id END)) AS QuestionCount,
    COUNT(DISTINCT (CASE WHEN RP.Level > 0 THEN RP.Id END)) AS AnswerCount,
    SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyReceived
FROM
    AggregatedData AD
LEFT JOIN
    RecursivePosts RP ON AD.UserId = RP.OwnerUserId
LEFT JOIN
    Votes V ON RP.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart votes
WHERE
    AD.TotalScore > 100 -- Filter: Only users with more than 100 reputation
GROUP BY
    AD.DisplayName, AD.TotalScore, AD.TotalPosts, AD.TotalComments,
    AD.AvgPostScore, AD.EditHistoryCount, AD.UniquePostsEdited, AD.LastEditDate
ORDER BY
    AD.TotalScore DESC, AD.TotalPosts DESC;

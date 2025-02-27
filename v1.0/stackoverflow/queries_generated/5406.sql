WITH UserStatistics AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBountyEarned,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN B.Name IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id
),
PostMetrics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        COALESCE(Ph.PostHistoryTypeId, 0) AS LastActionType
    FROM
        Posts P
    LEFT JOIN
        (SELECT PostId, MAX(CreationDate) AS LastActionDate
         FROM PostHistory
         GROUP BY PostId) AS LastAction ON P.Id = LastAction.PostId
    LEFT JOIN
        PostHistory Ph ON LastAction.PostId = Ph.PostId AND LastAction.LastActionDate = Ph.CreationDate
),
TopUsers AS (
    SELECT
        UserId,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBountyEarned,
        TotalUpVotes,
        TotalDownVotes,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM
        UserStatistics
)
SELECT
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalBountyEarned,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalBadges,
    P.Title,
    P.CreationDate,
    P.LastActivityDate,
    P.Score,
    P.ViewCount,
    P.LastActionType
FROM
    TopUsers U
INNER JOIN
    Posts P ON U.UserId = P.OwnerUserId
WHERE
    U.Rank <= 10
ORDER BY
    U.TotalPosts DESC, P.LastActivityDate DESC;

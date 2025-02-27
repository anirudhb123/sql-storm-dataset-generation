WITH UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.DisplayName,
        P.TotalPosts,
        P.Questions,
        P.Answers,
        P.TotalViews,
        P.TotalScore,
        R.ReputationRank
    FROM 
        UserRankings R
    JOIN 
        PostStatistics P ON R.UserId = P.OwnerUserId
    ORDER BY 
        R.ReputationRank
    LIMIT 10
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        CT.Name AS CloseReason 
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment::int = CT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.Questions,
    TU.Answers,
    TU.TotalViews,
    TU.TotalScore,
    COALESCE(CP.CloseReason, 'Not Closed') AS LastCloseReason
FROM 
    TopUsers TU
LEFT JOIN 
    ClosedPosts CP ON CP.PostId = (
        SELECT TOP 1 P.Id 
        FROM Posts P 
        WHERE P.OwnerUserId = TU.UserId 
        ORDER BY P.CreationDate DESC
    )
ORDER BY 
    TU.ReputationRank;

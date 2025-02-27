WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        PositiveScorePosts,
        NegativeScorePosts
    FROM 
        UserStats
    WHERE 
        UserRank <= 10
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.UserId AS CloserUserId,
        PH.CreationDate AS CloseDate,
        CT.Name AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        CloseReasonTypes CT ON PH.Comment::int = CT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalComments,
    COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
    COUNT(CP.PostId) AS ClosedPostCount
FROM 
    TopUsers TU
LEFT JOIN 
    ClosedPosts CP ON TU.UserId = CP.CloserUserId
GROUP BY 
    TU.UserId, TU.DisplayName, TU.Reputation, COALESCE(CP.CloseReason, 'Not Closed')
ORDER BY 
    TU.Reputation DESC,
    ClosedPostCount DESC;

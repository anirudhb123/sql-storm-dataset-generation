WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments,
        COUNT(V.Id) AS VoteCount,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(P.ViewCount, 0)) DESC) AS EngagementRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        TotalComments,
        VoteCount
    FROM 
        UserEngagement
    WHERE 
        EngagementRank <= 10
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        PH.CreationDate AS CloseDate,
        PH.Comment AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10
),
UserCloseReasons AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT CP.PostId) AS ClosedPostsCount,
        STRING_AGG(DISTINCT CP.CloseReason, '; ') AS CloseReasons
    FROM 
        Users U
    LEFT JOIN 
        ClosedPosts CP ON U.Id = CP.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    TU.DisplayName,
    TU.TotalViews,
    TU.TotalComments,
    TU.VoteCount,
    COALESCE(UCR.ClosedPostsCount, 0) AS ClosedPostsCount,
    COALESCE(UCR.CloseReasons, 'No closed posts') AS CloseReasons
FROM 
    TopUsers TU
LEFT JOIN 
    UserCloseReasons UCR ON TU.UserId = UCR.UserId
ORDER BY 
    TU.TotalViews DESC,
    TU.VoteCount DESC;

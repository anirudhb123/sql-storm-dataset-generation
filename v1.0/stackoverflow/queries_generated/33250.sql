WITH RecPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        P.Id
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalViews,
        TotalScore,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStats
)
SELECT 
    CU.DisplayName AS TopUser,
    CU.Reputation,
    CU.TotalPosts,
    CU.TotalViews,
    CU.TotalScore,
    CU.LastPostDate,
    COALESCE(RP.Title, 'No Posts Found') AS RecentPostTitle,
    COALESCE(RP.CommentCount, 0) AS RecentPostCommentCount,
    COALESCE(RP.UpvoteCount, 0) AS RecentPostUpvoteCount,
    COALESCE(RP.DownvoteCount, 0) AS RecentPostDownvoteCount
FROM 
    TopUsers CU
LEFT JOIN 
    RecPosts RP ON RP.UserPostRank = 1 AND RP.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = CU.UserId)
WHERE 
    CU.ScoreRank <= 10
ORDER BY 
    CU.TotalScore DESC;

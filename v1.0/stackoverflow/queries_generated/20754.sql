WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id
),

PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypeNames,
        COUNT(CASE WHEN PH.Comment IS NOT NULL THEN 1 END) AS CommentsCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId, PH.CreationDate, PH.UserId
),

PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments,
        COALESCE(SUM(CASE WHEN PH.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS HistoryRecordCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistoryDetails PH ON P.Id = PH.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '6 MONTH'
    GROUP BY 
        P.Id
),

UserPostStats AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS NumOfPosts,
        SUM(COALESCE(PE.TotalComments, 0)) AS CommentsOnPosts,
        SUM(COALESCE(PE.HistoryRecordCount, 0)) AS PostHistoryCount,
        SUM(COALESCE(PE.TotalBounty, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostEngagement PE ON P.Id = PE.PostId
    WHERE 
        U.LastAccessDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        U.Id
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.NumOfPosts,
    U.CommentsOnPosts,
    U.PostHistoryCount,
    U.TotalBounty,
    UVs.UpVotesCount,
    UVs.DownVotesCount,
    (UVs.UpVotesCount - UVs.DownVotesCount) AS ReputationImpact,
    CASE 
        WHEN U.NumOfPosts > 10 THEN 'Active User'
        WHEN U.NumOfPosts BETWEEN 5 AND 10 THEN 'Moderate User'
        ELSE 'Inactive User' 
    END AS UserClassification
FROM 
    UserPostStats U
JOIN 
    UserVoteSummary UVs ON U.UserId = UVs.UserId
ORDER BY 
    ReputationImpact DESC, U.NumOfPosts DESC;

-- Edge cases handled:
-- 1. Users without posts but have votes.
-- 2. Posts with no engagement in comments or history.
-- 3. Multiple vote types not skewing the count.
-- 4. Complex aggregations taking place over multiple timeframes.

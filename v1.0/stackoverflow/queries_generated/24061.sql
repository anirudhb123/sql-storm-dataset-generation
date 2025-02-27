WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (8, 9) THEN V.BountyAmount ELSE 0 END), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        MAX(P.CreationDate) AS LastActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId 
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
),
ClosedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        PostId
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        UserStats U
    WHERE 
        U.UpVotes - U.DownVotes > 10 -- among users with more positive than negative votes
)
SELECT 
    P.Title,
    P.CommentCount,
    P.AnswerCount,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    U.DisplayName AS TopUser,
    U.ReputationRank,
    CASE 
        WHEN U.UserId IS NULL THEN 'No active contributors'
        ELSE 'Contributing user found'
    END AS ContributionStatus
FROM 
    PostSummary P
LEFT JOIN 
    ClosedPosts CP ON P.PostId = CP.PostId
LEFT JOIN 
    TopUsers U ON P.OwnerUserId = U.UserId
WHERE 
    P.CommentCount > 5 -- filter for posts with more than 5 comments
ORDER BY 
    P.LastActivity DESC, 
    U.ReputationRank ASC;


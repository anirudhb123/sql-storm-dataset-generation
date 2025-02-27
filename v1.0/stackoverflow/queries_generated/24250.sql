WITH UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN O.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN O.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN O.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - 
            COALESCE(SUM(CASE WHEN O.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes O ON P.Id = O.PostId
    GROUP BY 
        U.Id, U.DisplayName
), 
CloseReasons AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        CRT.Name AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id  -- Note: casting comment to int for matching
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- Filtering for closed and reopened posts
    GROUP BY 
        PH.UserId, PH.PostId, CRT.Name
), 
Bounties AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 8 THEN V.BountyAmount ELSE 0 END) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        V.VoteTypeId = 8  -- BountyStart
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName,
    UReputation.PostCount,
    UReputation.Upvotes,
    UReputation.Downvotes,
    COALESCE(CloseReasons.CloseCount, 0) AS TotalCloseReasons,
    COALESCE(Bounties.TotalBounty, 0) AS TotalBounty,
    UReputation.ReputationRank
FROM 
    UserReputationCTE UReputation
LEFT JOIN 
    CloseReasons ON UReputation.UserId = CloseReasons.UserId 
LEFT JOIN 
    Bounties ON UReputation.UserId = (
        SELECT OwnerUserId
        FROM Posts
        WHERE Id = Bounties.PostId
    )
WHERE 
    UReputation.ReputationRank <= 10  -- Top 10 by reputation
ORDER BY 
    UReputation.ReputationRank;

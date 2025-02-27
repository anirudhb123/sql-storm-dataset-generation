
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounties,
        @row_num := @row_num + 1 AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.VoteTypeId IN (8, 9)  
    CROSS JOIN (SELECT @row_num := 0) AS r
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
), 
ClosedPostDetails AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS CloseDate,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory PH 
    WHERE 
        PH.PostHistoryTypeId = 10  
    GROUP BY 
        PH.PostId, PH.CreationDate
), 
RankedClosedPosts AS (
    SELECT 
        CP.PostId,
        @rank_num := @rank_num + 1 AS CloseRank
    FROM 
        ClosedPostDetails CP
    CROSS JOIN (SELECT @rank_num := 0) AS r
    ORDER BY 
        CP.CloseDate DESC
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.Views,
    UA.PostCount,
    UA.AnswerCount,
    UA.TotalBounties,
    COALESCE(RCP.CloseRank, 0) AS RecentClosedPostRank
FROM 
    UserActivity UA
LEFT JOIN 
    RankedClosedPosts RCP ON UA.UserId = RCP.PostId
WHERE 
    UA.Reputation > 1000 AND 
    UA.PostCount > 5
ORDER BY 
    UA.UserRank, RecentClosedPostRank DESC;

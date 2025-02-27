-- Performance Benchmarking Query

WITH PostAggregates AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty,
        AVG(Vote.Count) AS AverageVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        AVG(U.Reputation) AS AverageReputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    PA.PostId,
    PA.PostTypeId,
    PA.CommentCount,
    PA.TotalBounty,
    PA.AverageVoteCount,
    UR.AverageReputation,
    UR.BadgeCount,
    PHS.LastEditDate,
    PHS.EditCount
FROM 
    PostAggregates PA
JOIN 
    UserReputation UR ON PA.PostId = UR.UserId
JOIN 
    PostHistorySummary PHS ON PA.PostId = PHS.PostId
ORDER BY 
    PA.CommentCount DESC, PA.TotalBounty DESC;

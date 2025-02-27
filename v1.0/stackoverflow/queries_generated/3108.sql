WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS CloseDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::jsonb->>'CloseReasonId'::int = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    RA.PostId,
    RA.Title,
    RA.OwnerName,
    RA.CreationDate,
    RA.Score,
    RA.ViewCount,
    COALESCE(CP.CloseDate, 'Not Closed') AS CloseDate,
    COALESCE(CP.CloseReason, 'N/A') AS CloseReason,
    UA.TotalBounty,
    UA.TotalPosts,
    UA.TotalUpVotes,
    UA.TotalDownVotes
FROM 
    RankedPosts RA
LEFT JOIN 
    ClosedPostHistory CP ON RA.PostId = CP.PostId
JOIN 
    UserActivity UA ON RA.OwnerName = UA.UserId
WHERE 
    RA.ScoreRank = 1
ORDER BY 
    RA.Score DESC, RA.ViewCount DESC;

WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankScore,
        COUNT(C.*) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        HT.Name AS HistoryType
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes HT ON PH.PostHistoryTypeId = HT.Id
    WHERE 
        HT.Name LIKE '%Closed%'
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.CreationDate,
    RP.RankScore,
    RP.CommentCount,
    RP.TotalBounty,
    CU.BadgeCount,
    CASE 
        WHEN CP.PostId IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
JOIN 
    UserStats CU ON RP.OwnerUserId = CU.UserId
WHERE 
    RP.RankScore <= 3
ORDER BY 
    RP.Score DESC, CU.Reputation DESC;

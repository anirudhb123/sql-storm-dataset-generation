
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(IFNULL(V.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT V.PostId) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId 
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        H.PostId,
        COUNT(DISTINCT H.Id) AS CloseCount
    FROM 
        PostHistory H
    WHERE 
        H.PostHistoryTypeId = 10 
    GROUP BY 
        H.PostId
)
SELECT 
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    R.ViewCount,
    U.DisplayName,
    U.TotalBounty,
    U.TotalVotes,
    COALESCE(C.CloseCount, 0) AS NumberOfClosures
FROM 
    RankedPosts R
JOIN 
    UserStats U ON R.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE Id = R.PostId) 
LEFT JOIN 
    ClosedPosts C ON R.PostId = C.PostId
WHERE 
    R.Rank <= 5 
ORDER BY 
    R.Score DESC, R.CreationDate DESC;

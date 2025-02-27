WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(UP.Score) AS TotalScore
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Votes UP ON RP.PostId = UP.PostId AND UP.VoteTypeId IN (2, 6) -- considering only upvotes and close votes
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5
),
ClosedCount AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory PH
    GROUP BY 
        PostId
)
SELECT 
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    COALESCE(C.CloseCount, 0) AS CloseCount,
    R.ViewCount,
    R.OwnerDisplayName,
    U.PostCount,
    U.TotalScore
FROM 
    RankedPosts R
LEFT JOIN 
    ClosedCount C ON R.PostId = C.PostId
JOIN 
    TopUsers U ON R.OwnerUserId = U.OwnerUserId
WHERE 
    R.Rank = 1
ORDER BY 
    U.TotalScore DESC, R.ViewCount DESC
LIMIT 100;

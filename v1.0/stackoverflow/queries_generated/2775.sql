WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS UserPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= now() - interval '1 year'
        AND P.Score > 0
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS Upvotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
TopPostOwners AS (
    SELECT 
        R.PostId,
        R.Title,
        R.Score,
        R.CreationDate,
        U.DisplayName,
        US.TotalPosts,
        US.TotalScore
    FROM 
        RankedPosts R
    JOIN 
        Users U ON R.OwnerUserId = U.Id
    JOIN 
        UserStats US ON U.Id = US.UserId
    WHERE 
        R.UserPostRank <= 5
),
FilteredClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT CR.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON PH.Comment::int = CR.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Close or Reopen
    GROUP BY 
        PH.PostId
)

SELECT 
    TPO.Title,
    TPO.Score,
    TPO.CreationDate,
    TPO.DisplayName,
    TPO.TotalPosts,
    TPO.TotalScore,
    COALESCE(FCP.CloseCount, 0) AS ClosedCount,
    COALESCE(FCP.CloseReasons, 'No closures') AS CloseReasons
FROM 
    TopPostOwners TPO
LEFT JOIN 
    FilteredClosedPosts FCP ON TPO.PostId = FCP.PostId
ORDER BY 
    TPO.Score DESC, TPO.CreationDate DESC;

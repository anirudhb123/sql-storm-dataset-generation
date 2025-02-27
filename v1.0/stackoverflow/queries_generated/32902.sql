WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        P.Score,
        P.UserId,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RN
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only questions
        AND P.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(P.Id) >= 5 -- Users with 5 or more questions
),
RecentVotes AS (
    SELECT 
        V.PostId,
        V.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= DATEADD(month, -3, GETDATE()) -- Votes from the last 3 months
    GROUP BY 
        V.PostId, V.VoteTypeId
),
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= DATEADD(month, -6, GETDATE()) -- Changes in the last 6 months
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)

SELECT 
    P.Title,
    U.DisplayName AS Author,
    P.CreationDate AS PostDate,
    P.ViewCount,
    P.Score,
    COALESCE(RP.RN, 0) AS Rank,
    COALESCE(TU.TotalScore, 0) AS UserTotalScore,
    COALESCE(TU.AvgViewCount, 0) AS UserAvgViewCount,
    COALESCE(RV.VoteCount, 0) AS RecentVoteCount,
    COALESCE(PHA.ChangeCount, 0) AS HistoryChangeCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    RankedPosts RP ON P.Id = RP.Id
LEFT JOIN 
    TopUsers TU ON P.OwnerUserId = TU.UserId
LEFT JOIN 
    RecentVotes RV ON P.Id = RV.PostId
LEFT JOIN 
    PostHistoryAnalysis PHA ON P.Id = PHA.PostId
WHERE 
    P.PostTypeId = 1 -- Only questions
    AND (P.Score > 5 OR P.ViewCount > 100) -- Posts with significant score or view count
ORDER BY 
    P.CreationDate DESC;

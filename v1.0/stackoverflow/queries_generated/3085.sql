WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Questions only
        AND P.CreationDate > NOW() - INTERVAL '1 year'
),
AnswerStats AS (
    SELECT 
        ParentId,
        COUNT(*) AS AnswerCount,
        AVG(Score) AS AverageScore
    FROM 
        Posts
    WHERE 
        PostTypeId = 2 -- Answers only
    GROUP BY 
        ParentId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON C.Id = CAST(PH.Comment AS int)
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
),
TopClosedPosts AS (
    SELECT 
        CP.PostId,
        CP.CreationDate,
        CP.CloseReason,
        P.Title,
        R.Score,
        R.ViewCount
    FROM 
        ClosedPosts CP
    JOIN 
        RankedPosts R ON R.PostId = CP.PostId
    JOIN 
        Posts P ON P.Id = R.PostId
    WHERE 
        R.Rank <= 5
)
SELECT 
    T.Title,
    COALESCE(A.AnswerCount, 0) AS AnswerCount,
    COALESCE(A.AverageScore, 0) AS AverageScore,
    C.CloseReason,
    C.CreationDate AS ClosedDate,
    T.Score,
    T.ViewCount
FROM 
    TopClosedPosts T
LEFT JOIN 
    AnswerStats A ON A.ParentId = T.PostId
ORDER BY 
    T.Score DESC NULLS LAST
LIMIT 10;

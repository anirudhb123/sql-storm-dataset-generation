WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS RankByScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' -- posts created in the last year
        AND P.PostTypeId = 1  -- questions only
),
AnswerStatistics AS (
    SELECT 
        P.Id AS PostId,
        COUNT(A.Id) AS TotalAnswers,
        COALESCE(AVG(A.Score), 0) AS AvgAnswerScore
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1  -- questions only
    GROUP BY 
        P.Id
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PH.UserDisplayName,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- Post Closed and Post Reopened
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.Score,
    RP.ViewCount,
    RP.AnswerCount,
    AS.TotalAnswers,
    AS.AvgAnswerScore,
    COALESCE(CP.CreationDate, 'No Closure Info') AS LastClosedDate,
    COALESCE(CP.Comment, 'N/A') AS LastClosureComment,
    COALESCE(CP.UserDisplayName, 'System') AS ClosureUser
FROM 
    RankedPosts RP
LEFT JOIN 
    AnswerStatistics AS ON RP.PostId = AS.PostId
LEFT JOIN 
    ClosedPostHistory CP ON RP.PostId = CP.PostId AND CP.rn = 1  -- most recent closure
WHERE 
    RP.RankByScore <= 5 -- top 5 posts by score per type
ORDER BY 
    RP.PostTypeId, RP.Score DESC;

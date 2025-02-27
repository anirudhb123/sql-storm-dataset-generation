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
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND P.PostTypeId IN (1, 2) -- Only Questions and Answers
),
PostSummary AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        CASE 
            WHEN RP.Rank = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts RP
),
AggregatedStats AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
FinalOutput AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.OwnerDisplayName,
        PS.PostCategory,
        AS.UserId,
        AS.QuestionCount,
        AS.AnswerCount,
        AS.TotalBounty,
        AS.BadgeCount
    FROM 
        PostSummary PS
    JOIN 
        AggregatedStats AS ON PS.OwnerDisplayName = AS.UserId
)
SELECT 
    FO.PostId,
    FO.Title,
    FO.CreationDate,
    FO.Score,
    FO.ViewCount,
    FO.OwnerDisplayName,
    FO.PostCategory,
    FO.QuestionCount,
    FO.AnswerCount,
    COALESCE(FO.TotalBounty, 0) AS TotalBounty,
    FO.BadgeCount,
    STRING_AGG(DISTINCT PH.Comment, '; ') AS PostHistoryComments
FROM 
    FinalOutput FO
LEFT JOIN 
    PostHistory PH ON FO.PostId = PH.PostId
WHERE 
    FO.Score > 10 -- Only posts with more than 10 scores
    AND (FO.TotalBounty IS NULL OR FO.TotalBounty > 0)
GROUP BY 
    FO.PostId, FO.Title, FO.CreationDate, FO.Score, FO.ViewCount, FO.OwnerDisplayName, FO.PostCategory, FO.QuestionCount, FO.AnswerCount, FO.TotalBounty, FO.BadgeCount
ORDER BY 
    FO.Score DESC, FO.CreationDate DESC
LIMIT 100;

WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC, P.CreationDate ASC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only questions
        AND P.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountySpent,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS PostHistoryCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id
), 
ClosedQuestionReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CRT.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory PH
    INNER JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    RS.PostId,
    RS.Title,
    RS.CreationDate,
    RS.Score,
    RS.ViewCount,
    U.UserId,
    U.DisplayName,
    U.TotalBountySpent,
    U.BadgeCount,
    U.CommentCount,
    CQR.CloseReasonNames,
    CASE 
        WHEN U.BadgeCount > 5 THEN 'High Achiever'
        WHEN U.BadgeCount BETWEEN 3 AND 5 THEN 'Moderate Achiever'
        ELSE 'Novice'
    END AS UserRank,
    CASE 
        WHEN RS.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostClassification,
    COALESCE(CQR.CloseReasonNames, 'Not Closed') AS CloseReason
FROM 
    RankedPosts RS
JOIN 
    Users U ON RS.PostId = U.Id
LEFT JOIN 
    ClosedQuestionReasons CQR ON RS.PostId = CQR.PostId
WHERE 
    RS.PostRank <= 3
ORDER BY 
    RS.ViewCount DESC, 
    RS.Score DESC;

-- Additional corner cases
WITH SubqueryAB AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT V.UserId) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate < NOW() - INTERVAL '2 years'
    GROUP BY 
        P.Id
)
SELECT 
    P.Id AS PostId,
    P.Title,
    CASE 
        WHEN P.BountyAmount IS NULL THEN 'No Bounty'
        ELSE 'Has Bounty'
    END AS BountyStatus,
    SUBSTRING(P.Body FROM 1 FOR 100) AS ShortBody,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
    SUBQ.VoteCount
FROM 
    Posts P
LEFT JOIN 
    SubqueryAB SUBQ ON P.Id = SUBQ.PostId
WHERE 
    P.Score < 0 
    AND P.CreationDate < NOW() - INTERVAL '1 month'
    AND P.ViewCount IS NOT NULL
ORDER BY 
    P.CreationDate DESC;

WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS Rank
    FROM
        Posts P
)

SELECT
    U.DisplayName,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RPC.ViewCount
FROM
    Users U
LEFT JOIN (
    SELECT
        UserId,
        COUNT(*) AS BadgeCount
    FROM
        Badges
    GROUP BY
        UserId
) B ON U.Id = B.UserId
LEFT JOIN RankedPosts RP ON U.Id = RP.OwnerUserId AND RP.Rank <= 3
LEFT JOIN (
    SELECT 
        P.OwnerUserId,
        SUM(P.ViewCount) AS ViewCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
) RPC ON U.Id = RPC.OwnerUserId
WHERE
    RP.PostId IS NOT NULL
    AND (U.Reputation > 1000 OR B.BadgeCount > 0)
    AND NOT EXISTS (
        SELECT 1
        FROM Votes V
        WHERE V.PostId = RP.PostId 
        AND V.VoteTypeId IN (2, 3) -- UpMod and DownMod
        GROUP BY V.PostId
        HAVING COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) < COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END)
    )
ORDER BY 
    U.DisplayName,
    RP.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;

WITH ClosingReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CAST(CRT.Name AS VARCHAR), ', ') AS Reasons
    FROM 
        PostHistory PH
    INNER JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- Post Closed and Post Reopened
    GROUP BY 
        PH.PostId
)

SELECT 
    P.Id,
    P.Title,
    P.CreationDate,
    COALESCE(CR.Reasons, 'No reasons provided') AS CloseReasons
FROM 
    Posts P
LEFT JOIN 
    ClosingReasons CR ON P.Id = CR.PostId
WHERE 
    EXISTS (
        SELECT 1
        FROM PostHistory PH
        WHERE PH.PostId = P.Id
        AND PH.PostHistoryTypeId = 10  -- Only show posts that have been closed
    )
ORDER BY 
    P.CreationDate DESC
LIMIT 50;

SELECT 
    DISTINCT ON (P.Id)
    P.Id AS PostId,
    P.Title,
    PO.OwnerDisplayName AS Owner,
    V.VoteTypeId AS LastVoteType
FROM 
    Posts P
LEFT JOIN 
    Users PO ON P.OwnerUserId = PO.Id
LEFT JOIN LATERAL (
    SELECT 
        V.VoteTypeId 
    FROM 
        Votes V
    WHERE 
        V.PostId = P.Id
    ORDER BY 
        V.CreationDate DESC
    LIMIT 1
) V ON true
WHERE 
    P.AnswerCount IS NOT NULL
    AND P.AnswerCount > 0
    AND P.CreationDate > NOW() - INTERVAL '6 months'
ORDER BY 
    P.CreationDate DESC;

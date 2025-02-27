WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Filter for posts created in the last year
),
UsersWithBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
CloseReasonDetails AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CRT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    INNER JOIN 
        CloseReasonTypes CRT ON PH.Comment = CAST(CRT.Id AS varchar)
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Filter for close and reopen actions
    GROUP BY 
        PH.PostId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.Rank,
    U.DisplayName,
    U.BadgeCount,
    COALESCE(CRD.CloseReasons, 'No closure reasons') AS CloseReasons,
    (UP.VoteCount - DP.VoteCount) AS VoteBalance,
    NULLIF(UP.VoteCount + DP.VoteCount, 0) AS TotalVoteCount -- Return NULL if total vote count is zero
FROM 
    RankedPosts RP
JOIN 
    UsersWithBadges U ON RP.OwnerUserId = U.UserId
LEFT JOIN 
    CloseReasonDetails CRD ON RP.PostId = CRD.PostId
OUTER APPLY (
    SELECT COUNT(*) AS VoteCount
    FROM Votes V
    WHERE V.PostId = RP.PostId AND V.VoteTypeId = 2 -- Count upvotes
) AS UP
OUTER APPLY (
    SELECT COUNT(*) AS VoteCount
    FROM Votes V
    WHERE V.PostId = RP.PostId AND V.VoteTypeId = 3 -- Count downvotes
) AS DP
WHERE 
    RP.Rank <= 5 -- Limit to top 5 posts per user
ORDER BY 
    RP.ViewCount DESC, RP.Score DESC;

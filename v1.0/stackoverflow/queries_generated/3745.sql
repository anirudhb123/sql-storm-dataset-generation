WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) as PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' 
        AND P.ViewCount > 100
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName
), CTE_CLOSED AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        CRT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
        AND PH.CreationDate >= NOW() - INTERVAL '1 year'
), CTE_TOTAL_VOTES AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.CreationDate,
    RP.UpVotes,
    RP.DownVotes,
    COALESCE(CC.CloseReason, 'Not Closed') AS CloseReason,
    TV.TotalUpVotes,
    TV.TotalDownVotes
FROM 
    RankedPosts RP
LEFT JOIN 
    CTE_CLOSED CC ON RP.PostId = CC.PostId
LEFT JOIN 
    CTE_TOTAL_VOTES TV ON RP.PostId = TV.PostId
WHERE 
    RP.PostRank <= 5
ORDER BY 
    RP.Score DESC;

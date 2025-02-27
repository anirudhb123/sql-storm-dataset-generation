
WITH RecursiveTopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Location,
        @rownum := @rownum + 1 AS Rank
    FROM 
        Users U, (SELECT @rownum := 0) r
    WHERE 
        U.Reputation IS NOT NULL
    AND 
        U.Reputation > 0
    ORDER BY 
        U.Reputation DESC
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        COALESCE(PV.VoteCount, 0) AS VoteCount,
        COALESCE(C.LastCommentCount, 0) AS LastCommentCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId IN (2, 3) 
        GROUP BY 
            PostId
    ) PV ON P.Id = PV.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS LastCommentCount
        FROM 
            Comments
        WHERE 
            CreationDate >= CURDATE() - INTERVAL 30 DAY
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURDATE() - INTERVAL 60 DAY
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        GROUP_CONCAT(PHT.Name SEPARATOR ', ') AS HistoryTypes,
        COUNT(PH.Id) AS TotalHistoryEntries
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName AS TopUser,
    R.Reputation,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS PostCreationDate,
    RP.Score AS PostScore,
    RP.VoteCount AS TotalVotes,
    C.CommentCount AS TotalComments,
    PHS.HistoryTypes,
    PHS.TotalHistoryEntries
FROM 
    RecursiveTopUsers R
JOIN 
    Users U ON R.Id = U.Id
JOIN 
    RecentPosts RP ON RP.OwnerUserId = U.Id
LEFT JOIN 
    (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) C ON RP.PostId = C.PostId
LEFT JOIN 
    PostHistorySummary PHS ON RP.PostId = PHS.PostId
WHERE 
    R.Rank <= 10
ORDER BY 
    R.Reputation DESC, RP.CreationDate DESC;

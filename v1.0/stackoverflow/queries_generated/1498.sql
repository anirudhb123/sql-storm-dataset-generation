WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= current_date - interval '1 year'
), 
TotalVotes AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CommentsCount AS (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    COALESCE(TV.UpVotes, 0) AS UpVotes,
    COALESCE(TV.DownVotes, 0) AS DownVotes,
    COALESCE(CC.CommentCount, 0) AS TotalComments,
    RP.ViewCount,
    CASE 
        WHEN RP.PostRank = 1 THEN 'Top Post'
        ELSE NULL 
    END AS RankDescription
FROM 
    RankedPosts RP
LEFT JOIN 
    TotalVotes TV ON RP.PostId = TV.PostId
LEFT JOIN 
    CommentsCount CC ON RP.PostId = CC.PostId
WHERE 
    RP.PostRank <= 5
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC;

WITH PostHistoryCTE AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstEditDate,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount,
        MAX(PH.PostHistoryTypeId) AS LastAction
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    GROUP BY 
        PH.PostId
)
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    PHC.FirstEditDate,
    PHC.LastEditDate,
    PHC.EditCount,
    CASE 
        WHEN PHC.LastAction = 4 THEN 'Last edit was title change'
        WHEN PHC.LastAction = 5 THEN 'Last edit was body change'
        WHEN PHC.LastAction = 6 THEN 'Last edit was tags change'
        ELSE 'No relevant edits'
    END AS EditActionDescription
FROM 
    Posts P
LEFT JOIN 
    PostHistoryCTE PHC ON P.Id = PHC.PostId
WHERE 
    P.AcceptedAnswerId IS NOT NULL 
    AND P.Score > 0
ORDER BY 
    PHC.LastEditDate DESC;

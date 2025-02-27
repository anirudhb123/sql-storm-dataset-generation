WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankWithinUser,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
TopUserPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankWithinUser <= 3
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes,
        COUNT(*) AS EditCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    TUP.Title,
    TUP.CreationDate,
    TUP.Score,
    TUP.ViewCount,
    TUP.OwnerDisplayName,
    COALESCE(PHD.HistoryTypes, 'No Edits') AS HistoryTypes,
    COALESCE(PHD.EditCount, 0) AS EditCount,
    (TUP.Score + TUP.ViewCount) * 1.0 / NULLIF(TUP.UpvoteCount + TUP.DownvoteCount, 0) AS EngagementRate
FROM 
    TopUserPosts TUP
LEFT JOIN 
    PostHistoryDetails PHD ON TUP.PostId = PHD.PostId
ORDER BY 
    EngagementRate DESC
LIMIT 10;

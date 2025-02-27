WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATEADD(year, -1, GETDATE())
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        Reputation
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(C.Text, '; ') AS Comments
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(CONVERT(varchar, PH.PostHistoryTypeId) + ': ' + PH.Comment, '; ') AS HistoryComments
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete
    GROUP BY 
        PH.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.CreationDate,
    TP.Reputation,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    COALESCE(PC.Comments, 'No comments') AS Comments,
    COALESCE(PHD.LastEditDate, 'Never') AS LastEditDate,
    COALESCE(PHD.HistoryComments, 'No history') AS HistoryComments
FROM 
    TopPosts TP
LEFT JOIN 
    PostComments PC ON TP.PostId = PC.PostId
LEFT JOIN 
    PostHistoryDetails PHD ON TP.PostId = PHD.PostId
ORDER BY 
    TP.Score DESC;

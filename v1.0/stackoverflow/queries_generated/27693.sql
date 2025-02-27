WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.ID) AS CommentCount,
        PT.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.Score DESC) AS UserRank,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS RunRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days' -- Posts created in the last 30 days
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName, PT.Name
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.PostType,
        RP.RunRank
    FROM 
        RankedPosts RP
    WHERE 
        RP.RunRank <= 10 -- Top 10 most viewed posts
),
PostStats AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.OwnerDisplayName,
        TP.CommentCount,
        TP.PostType,
        PH.PostHistoryTypeId,
        PH.CreationDate AS HistoryDate,
        PH.UserDisplayName AS EditorDisplayName,
        PH.Comment AS EditComment
    FROM 
        TopPosts TP
    LEFT JOIN 
        PostHistory PH ON TP.PostId = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) -- Title and body edits
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.OwnerDisplayName,
    PS.CommentCount,
    PS.PostType,
    STRING_AGG(CONCAT(PS.EditorDisplayName, ' | ', PS.EditComment, ' | ', TO_CHAR(PS.HistoryDate, 'YYYY-MM-DD HH24:MI:SS')), '; ' ORDER BY PS.HistoryDate DESC) AS EditHistory
FROM 
    PostStats PS
GROUP BY 
    PS.PostId, PS.Title, PS.OwnerDisplayName, PS.CommentCount, PS.PostType
ORDER BY 
    PS.CommentCount DESC;

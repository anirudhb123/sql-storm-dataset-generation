WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
CommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostHistoryTypesFiltered AS (
    SELECT 
        PHT.PostId, 
        COUNT(PHT.Id) AS HistoryCount,
        MAX(PHT.CreationDate) AS LastModified
    FROM 
        PostHistory PHT
    GROUP BY 
        PHT.PostId
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        COALESCE(CC.TotalComments, 0) AS TotalComments,
        COALESCE(PHTF.HistoryCount, 0) AS HistoryCount,
        PHTF.LastModified
    FROM 
        RankedPosts RP
    LEFT JOIN 
        CommentCounts CC ON RP.PostId = CC.PostId
    LEFT JOIN 
        PostHistoryTypesFiltered PHTF ON RP.PostId = PHTF.PostId
    WHERE 
        RP.RankScore <= 10 -- Top 10 posts for each type
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.OwnerDisplayName,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.TotalComments,
    TP.HistoryCount,
    TP.LastModified,
    CASE 
        WHEN TP.Score IS NULL OR TP.Score <= 0 THEN 'No Score'
        ELSE 'Scored'
    END AS ScoreStatus,
    CONCAT('Post "', TP.Title, '" by ', TP.OwnerDisplayName, 
           ' has ', TP.TotalComments, ' comments '
           , CASE 
                WHEN TP.HistoryCount > 0 THEN 'and has been modified ' 
                ELSE 'and has not been modified ' 
             END, 
           'last modified on ', 
           COALESCE(TO_CHAR(TP.LastModified, 'YYYY-MM-DD HH24:MI:SS'), 'never'))
    AS PostDetails
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC, TP.CreationDate DESC;

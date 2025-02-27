WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.CommentCount,
    TP.VoteCount,
    CONCAT_WS(', ', ARRAY_AGG(DISTINCT T.TagName)) AS Tags
FROM 
    TopPosts TP
LEFT JOIN 
    PostsTags PT ON TP.PostId = PT.PostId
LEFT JOIN 
    Tags T ON PT.TagId = T.Id
GROUP BY 
    TP.PostId, TP.Title, TP.Score, TP.ViewCount, TP.CommentCount, TP.VoteCount
ORDER BY 
    TP.Score DESC

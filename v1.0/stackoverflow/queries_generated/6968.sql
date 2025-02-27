WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Comment) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(C.Comment) DESC, COUNT(V.Id) DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND P.PostTypeId = 1  -- Only consider questions
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, OwnerDisplayName, CommentCount, VoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5  -- Top 5 posts per user
)
SELECT 
    TP.OwnerDisplayName,
    TP.Title, 
    TP.CreationDate, 
    TP.CommentCount, 
    TP.VoteCount,
    COUNT(DISTINCT PHT.Comment) AS HistoryCommentCount,
    STRING_AGG(DISTINCT PHT.Comment, '; ') AS HistoryComments
FROM 
    TopPosts TP
JOIN 
    PostHistory PHT ON TP.PostId = PHT.PostId
WHERE 
    PHT.CreationDate >= CURRENT_DATE - INTERVAL '60 days'
GROUP BY 
    TP.OwnerDisplayName, TP.Title, TP.CreationDate, TP.CommentCount, TP.VoteCount
ORDER BY 
    TP.CommentCount DESC, TP.VoteCount DESC;

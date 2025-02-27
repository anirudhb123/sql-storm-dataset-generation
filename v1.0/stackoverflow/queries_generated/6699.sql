WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND P.Score > 0
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerName,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
),
PostSummary AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.OwnerName,
        TP.CreationDate,
        TP.Score,
        TP.ViewCount,
        TP.AnswerCount,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        TopPosts TP
    LEFT JOIN 
        Comments C ON TP.PostId = C.PostId
    LEFT JOIN 
        Votes V ON TP.PostId = V.PostId AND V.VoteTypeId IN (8, 9)
    GROUP BY 
        TP.PostId, TP.Title, TP.OwnerName, TP.CreationDate, 
        TP.Score, TP.ViewCount, TP.AnswerCount
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.OwnerName,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.TotalBounty,
    T.TagName
FROM 
    PostSummary PS
JOIN 
    Posts P ON PS.PostId = P.Id
JOIN 
    Tags T ON T.Id IN (SELECT UNNEST(STRING_TO_ARRAY(P.Tags, '>'))::int) 
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC;

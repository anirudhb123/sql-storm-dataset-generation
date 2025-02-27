
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        U.Id AS OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        P.CreationDate,
        P.LastActivityDate,
        P.ViewCount,
        P.Score
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, U.Id, P.CreationDate, P.LastActivityDate, P.ViewCount, P.Score
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        PostTypeId, 
        OwnerUserId, 
        CommentCount, 
        VoteCount, 
        CreationDate, 
        LastActivityDate, 
        ViewCount, 
        Score,
        @row_number := IF(@prev_score = Score, @row_number, @row_number + 1) AS Rank,
        @prev_score := Score
    FROM 
        PostStats, (SELECT @row_number := 0, @prev_score := NULL) AS vars
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.PostTypeId,
    U.DisplayName AS OwnerDisplayName,
    TP.CommentCount,
    TP.VoteCount,
    TP.CreationDate,
    TP.LastActivityDate,
    TP.ViewCount,
    TP.Score
FROM 
    TopPosts TP
JOIN 
    Users U ON TP.OwnerUserId = U.Id
WHERE 
    TP.Rank <= 100;

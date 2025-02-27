
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        U.Reputation,
        @row_number := IF(@prev_post_type = PT.Name, @row_number + 1, 1) AS ScoreRank,
        @prev_post_type := PT.Name,
        COUNT(V.Id) AS UpvoteCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := '') AS vars
    WHERE 
        P.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY 
        P.Id, P.Title, P.Score, U.Reputation, PT.Name
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        Reputation, 
        ScoreRank, 
        UpvoteCount, 
        CommentCount, 
        EditCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.Reputation,
    TP.UpvoteCount,
    TP.CommentCount,
    TP.EditCount,
    PT.Name AS PostType
FROM 
    TopPosts TP
JOIN 
    PostTypes PT ON PT.Id = (SELECT PostTypeId FROM Posts WHERE Id = TP.PostId)
ORDER BY 
    TP.Score DESC, 
    TP.UpvoteCount DESC;

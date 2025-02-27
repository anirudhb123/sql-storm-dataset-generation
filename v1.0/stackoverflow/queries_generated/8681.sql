WITH RankedPosts AS (
    SELECT 
        P.Id as PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.CommentCount,
        RP.VoteCount,
        PT.Name as PostTypeName
    FROM 
        RankedPosts RP
    JOIN 
        PostTypes PT ON RP.PostId = PT.Id
    WHERE 
        RP.Rank <= 10
)
SELECT 
    T.PostId,
    T.Title,
    T.CreationDate,
    T.Score,
    T.ViewCount,
    T.CommentCount,
    T.VoteCount,
    T.PostTypeName,
    U.DisplayName as Author,
    U.Reputation as AuthorReputation,
    U.CreationDate as AuthorCreationDate
FROM 
    TopPosts T
JOIN 
    Users U ON T.OwnerUserId = U.Id
ORDER BY 
    T.PostTypeName, T.Score DESC;

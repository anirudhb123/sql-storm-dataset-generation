WITH RankedPosts AS (
    SELECT 
        P.Id as PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName as OwnerDisplayName,
        COUNT(C.Id) as CommentCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) as RankScore
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.Score,
        RP.OwnerDisplayName
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankScore <= 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.ViewCount,
    TP.Score,
    TP.OwnerDisplayName,
    PT.Name as PostType,
    COUNT(V.Id) as TotalVotes,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) as UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) as DownVotes,
    SUM(CASE WHEN V.VoteTypeId IN (6, 10) THEN 1 ELSE 0 END) as CloseVotes
FROM 
    TopPosts TP
LEFT JOIN 
    Votes V ON TP.PostId = V.PostId
LEFT JOIN 
    PostTypes PT ON TP.PostId = PT.Id
GROUP BY 
    TP.PostId, TP.Title, TP.ViewCount, TP.Score, TP.OwnerDisplayName, PT.Name
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;

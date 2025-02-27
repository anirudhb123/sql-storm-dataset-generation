WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ARRAY_AGG(T.TagName) AS Tags,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        (SELECT unnest(string_to_array(Tags, '>')) AS TagName, PostId FROM Posts) T ON P.Id = T.PostId
    GROUP BY 
        P.Id, U.DisplayName
), 
TopPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    TP.*,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = TP.Id AND V.VoteTypeId IN (2, 3)) AS TotalVotes
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;

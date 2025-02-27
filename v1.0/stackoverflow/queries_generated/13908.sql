-- Performance Benchmarking Query
WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.Reputation AS OwnerReputation,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        UNNEST(string_to_array(P.Tags, '><')) AS TagId ON TRUE
    LEFT JOIN 
        Tags T ON T.Id = CAST(TRIM(BOTH '<>' FROM TagId) AS int)
    GROUP BY 
        P.Id, U.Reputation
),
VoteDetails AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.OwnerReputation,
    PD.CommentCount,
    PD.AnswerCount,
    VD.UpVotes,
    VD.DownVotes,
    PD.Tags
FROM 
    PostDetails PD
LEFT JOIN 
    VoteDetails VD ON PD.PostId = VD.PostId
ORDER BY 
    PD.Score DESC, PD.ViewCount DESC
LIMIT 100;

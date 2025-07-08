
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        LISTAGG(DISTINCT T.TagName, ',') AS Tags,
        RANK() OVER (ORDER BY COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) - COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) DESC) AS VoteRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(P.Tags, '><')) AS T ON TRUE
    WHERE 
        P.CreationDate >= DATEADD(day, -30, '2024-10-01') 
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.ViewCount
),

PostActivity AS (
    SELECT 
        RH.PostId,
        RH.Title,
        RH.ViewCount,
        RH.UpVotes,
        RH.DownVotes,
        RH.CommentCount,
        RANK() OVER (ORDER BY RH.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY RH.UpVotes DESC) AS UpVoteRank,
        RANK() OVER (ORDER BY RH.CommentCount DESC) AS CommentRank
    FROM 
        RankedPosts RH
)

SELECT 
    PA.PostId,
    PA.Title,
    PA.ViewCount,
    PA.UpVotes,
    PA.DownVotes,
    PA.CommentCount,
    PA.ViewRank,
    PA.UpVoteRank,
    PA.CommentRank,
    COALESCE(LISTAGG(DISTINCT T.TagName, ','), '') AS Tags
FROM 
    PostActivity PA
LEFT JOIN 
    Posts P ON PA.PostId = P.Id
LEFT JOIN 
    LATERAL FLATTEN(INPUT => SPLIT(P.Tags, '><')) AS T ON TRUE
GROUP BY 
    PA.PostId, PA.Title, PA.ViewCount, PA.UpVotes, PA.DownVotes, PA.CommentCount, PA.ViewRank, PA.UpVoteRank, PA.CommentRank
ORDER BY 
    PA.ViewRank, PA.UpVoteRank, PA.CommentRank
LIMIT 10;

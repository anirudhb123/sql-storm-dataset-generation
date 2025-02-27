WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1  -- Only questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.ViewCount, U.DisplayName
),

PostTags AS (
    SELECT 
        PostId,
        STRING_AGG(DISTINCT TRIM(BOTH '<>' FROM UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><'))), ', ') AS Tags
    FROM 
        Posts
    GROUP BY 
        PostId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    RP.ViewCount,
    RP.OwnerDisplayName,
    RP.UpVotes,
    RP.DownVotes,
    RP.CommentCount,
    PT.Tags
FROM 
    RankedPosts RP
JOIN 
    PostTags PT ON RP.PostId = PT.PostId
WHERE 
    RP.PostRank = 1  -- Get the most recent post for each user
ORDER BY 
    RP.ViewCount DESC, RP.UpVotes - RP.DownVotes DESC  -- Order by view count and net votes
LIMIT 10;  -- Limit to the top 10 results for benchmarking

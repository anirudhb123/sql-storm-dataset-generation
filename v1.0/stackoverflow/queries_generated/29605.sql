WITH PostTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        STRING_AGG(T.TagName, ', ') AS TagNames,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.ID) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON T.Id = ANY(STRING_TO_ARRAY(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><')::int[])
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 AND -- Only considering questions
        P.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        P.Id, U.DisplayName
),
RankedPosts AS (
    SELECT 
        PT.*,
        RANK() OVER (ORDER BY PT.ViewCount DESC, PT.Score DESC) AS Rank
    FROM 
        PostTags PT
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.TagNames,
    RP.ViewCount,
    RP.Score,
    RP.OwnerDisplayName,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.Rank
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 10; -- Get top 10 posts

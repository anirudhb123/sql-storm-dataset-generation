WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        P.Score,
        U.Reputation AS OwnerReputation,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
        AND P.PostTypeId = 1  -- Only questions
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        AnswerCount,
        CreationDate,
        Score,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 5  -- Top 5 by score in each type
),
PostTagStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT T.TagName) AS TagCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        UNNEST(string_to_array(P.Tags, '>')) AS tag ON tag IS NOT NULL
    JOIN 
        Tags T ON T.TagName = TRIM(tag)
    GROUP BY 
        P.Id
),
CombinedStats AS (
    SELECT 
        TP.*,
        PTS.TagCount,
        PTS.Tags
    FROM 
        TopPosts TP
    LEFT JOIN 
        PostTagStats PTS ON TP.PostId = PTS.PostId
)
SELECT 
    PostId,
    Title,
    ViewCount,
    AnswerCount,
    CreationDate,
    Score,
    OwnerReputation,
    TagCount,
    Tags
FROM 
    CombinedStats
ORDER BY 
    Score DESC,
    CreationDate DESC;

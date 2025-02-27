WITH TagCounts AS (
    SELECT
        UNNEST(string_to_array(Posts.Tags, '>')) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE 
        Posts.PostTypeId = 1  -- Considering only questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1 -- Only include tags used by more than 1 question
),
HighScorePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        U.DisplayName AS Author,
        P.CreationDate
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Score > 50 
        AND P.PostTypeId = 1 -- Questions
),
TrendingTopics AS (
    SELECT 
        HT.Tag AS TrendingTag,
        HT.PostCount,
        H.PostId,
        H.Title,
        H.Score,
        H.Author,
        H.CreationDate
    FROM 
        TopTags HT
    JOIN 
        HighScorePosts H ON H.Title ILIKE '%' || HT.Tag || '%'
)
SELECT 
    TT.TrendingTag,
    TT.PostCount,
    TT.PostId,
    TT.Title,
    TT.Score,
    TT.Author,
    TT.CreationDate,
    COALESCE(CT.CommentCount, 0) AS CommentCount,
    COALESCE(V.VoteCount, 0) AS UpVoteCount
FROM 
    TrendingTopics TT
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments 
    GROUP BY 
        PostId
) CT ON TT.PostId = CT.PostId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS VoteCount
    FROM 
        Votes 
    WHERE 
        VoteTypeId = 2 -- UpMod (upvote)
    GROUP BY 
        PostId
) V ON TT.PostId = V.PostId
ORDER BY 
    TT.PostCount DESC, 
    TT.Score DESC
LIMIT 10;

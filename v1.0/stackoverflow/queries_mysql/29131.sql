
WITH TagCounts AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Posts.Tags, '>', numbers.n), '>', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Posts.Tags) - CHAR_LENGTH(REPLACE(Posts.Tags, '>', '')) >= numbers.n - 1
    WHERE 
        Posts.PostTypeId = 1  
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        @row_number := @row_number + 1 AS TagRank
    FROM 
        TagCounts, (SELECT @row_number := 0) AS rn
    WHERE 
        PostCount > 1 
    ORDER BY PostCount DESC
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
        AND P.PostTypeId = 1 
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
        HighScorePosts H ON H.Title LIKE CONCAT('%', HT.Tag, '%')
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
        VoteTypeId = 2 
    GROUP BY 
        PostId
) V ON TT.PostId = V.PostId
ORDER BY 
    TT.PostCount DESC, 
    TT.Score DESC
LIMIT 10;

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ARRAY_LENGTH(STRING_TO_ARRAY(P.Tags, '>'), 1) AS TagCount,
        U.DisplayName AS OwnerName,
        U.Reputation AS OwnerReputation,
        COALESCE(A.AnswerCount, 0) AS AnswerCount,
        COALESCE(A.CommentCount, 0) AS CommentCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount,
            SUM(CommentCount) AS CommentCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 -- Answer
        GROUP BY 
            ParentId
    ) A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1 -- Question
),
TaggedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.TagCount,
        PS.ViewCount,
        PS.Score,
        PS.OwnerName,
        PS.OwnerReputation,
        PS.AnswerCount,
        PS.CommentCount,
        T.TagName
    FROM 
        PostStats PS
    JOIN 
        LATERAL UNNEST(STRING_TO_ARRAY(PS.Tags, '>')) AS T(TagName) ON TRUE
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY TagName ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        TaggedPosts
)
SELECT 
    PostId,
    Title,
    TagName,
    OwnerName,
    OwnerReputation,
    AnswerCount,
    CommentCount
FROM 
    RankedPosts
WHERE 
    Rank <= 5
ORDER BY 
    TagName, Rank;
This SQL query retrieves the top 5 most popular questions (based on score and view count) per tag from a Stack Overflow-like schema. It first gathers relevant statistics about questions and their respective owners, correlates them with their tags, and finally ranks them to output the top questions along with some of their key details.

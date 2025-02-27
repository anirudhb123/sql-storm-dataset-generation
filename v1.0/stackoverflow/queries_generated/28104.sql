-- This SQL query benchmarks string processing by retrieving detailed information
-- about posts alongside the users who created them, including string manipulations
-- for tags and post titles, as well as calculating the length of various text fields.

WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS Author,
        U.Reputation,
        CASE 
            WHEN P.PostTypeId = 1 THEN 'Question'
            WHEN P.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        LENGTH(P.Body) AS BodyLength,
        LENGTH(P.Title) AS TitleLength,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        P.CreationDate,
        P.LastActivityDate,
        P.CommentCount,
        P.FavoriteCount,
        P.ClosedDate,
        ARRAY_LENGTH(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><'), 1) AS TagCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'  -- Focus on recent posts
),
TagConversion AS (
    SELECT 
        P.PostId,
        P.Author,
        P.PostType,
        P.BodyLength,
        P.TitleLength,
        P.TagCount,
        STRING_AGG(T.TagName, ', ') AS TagList
    FROM 
        PostDetails P
    LEFT JOIN 
        Tags T ON (T.TagName = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')))  -- Convert string tags to array
    GROUP BY 
        P.PostId, P.Author, P.PostType, P.BodyLength, P.TitleLength, P.TagCount
)
SELECT 
    TC.PostId,
    TC.Author,
    TC.PostType,
    TC.BodyLength,
    TC.TitleLength,
    TC.TagCount,
    TC.TagList,
    COUNT(C.Id) AS CommentCount,  -- Count of comments related to posts
    SUM(CASE WHEN C.Score > 0 THEN 1 ELSE 0 END) AS Upvotes,  -- Positive comment scores count
    SUM(CASE WHEN C.Score < 0 THEN 1 ELSE 0 END) AS Downvotes  -- Negative comment scores count
FROM 
    TagConversion TC
LEFT JOIN 
    Comments C ON C.PostId = TC.PostId
GROUP BY 
    TC.PostId, TC.Author, TC.PostType, TC.BodyLength, TC.TitleLength, TC.TagCount, TC.TagList
ORDER BY 
    TC.BodyLength DESC, TC.TitleLength DESC;  -- Order by body length and title length


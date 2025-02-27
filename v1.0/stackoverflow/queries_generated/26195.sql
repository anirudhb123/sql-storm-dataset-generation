WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS Author,
        COUNT(C.CommentId) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT 
            C.Id AS CommentId, 
            C.PostId 
         FROM 
            Comments C) C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 -- filtering for Questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Author,
        CommentCount,
        UpvoteCount,
        DownvoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1 -- only the latest version of each post
)

SELECT 
    FP.PostId,
    FP.Title,
    LEFT(FP.Body, 200) AS Snippet, -- Preview of the post body
    FP.CreationDate,
    FP.Author,
    FP.CommentCount,
    FP.UpvoteCount,
    FP.DownvoteCount,
    (FP.UpvoteCount - FP.DownvoteCount) AS NetVotes,
    (SELECT STRING_AGG(Tag.TagName, ', ') 
     FROM Tags Tag
     JOIN LATERAL (
         SELECT UNNEST(STRING_TO_ARRAY(P.Tags, '><')) AS tag -- Parsing the tags
     ) AS TagsArray ON TagsArray.tag = Tag.TagName
     WHERE Tag.WikiPostId IS NULL) AS ParsedTags 
FROM 
    FilteredPosts FP
ORDER BY 
    NetVotes DESC, -- Sorting by most popular
    FP.CreationDate DESC
LIMIT 10; -- Return the top 10 posts

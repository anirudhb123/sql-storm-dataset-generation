WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Body,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Questions
),
TagCounts AS (
    SELECT 
        UNNEST(string_to_array(P.Tags, '><')) AS Tag,
        COUNT(*) AS TagUsage
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10 -- Only include tags used more than 10 times
),
PostStats AS (
    SELECT 
        R.PostId,
        R.Title,
        R.Author,
        R.CreationDate,
        R.ViewCount,
        R.Body,
        TC.Tag AS FrequentTag,
        TC.TagUsage
    FROM 
        RankedPosts R
    JOIN 
        TagCounts TC ON TC.Tag = ANY(string_to_array(R.Body, ' ')) -- Find posts that contain frequent tags in the body
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Author,
    PS.CreationDate,
    PS.ViewCount,
    PS.Body,
    PS.FrequentTag,
    PS.TagUsage,
    COUNT(C.Id) AS CommentCount
FROM 
    PostStats PS
LEFT JOIN 
    Comments C ON C.PostId = PS.PostId
GROUP BY 
    PS.PostId, PS.Title, PS.Author, PS.CreationDate, PS.ViewCount, PS.Body, PS.FrequentTag, PS.TagUsage
ORDER BY 
    PS.ViewCount DESC
LIMIT 10; -- Return the top 10 most viewed questions containing popular tags

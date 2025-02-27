WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        ARRAY(SELECT TRIM(REGEXP_SPLIT_TO_TABLE(P.Tags, '><'))) AS TagsArray,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Only questions
        AND P.CreationDate >= DATE_TRUNC('year', CURRENT_DATE)  -- This year's posts
),

UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

TopTags AS (
    SELECT 
        TRIM(REGEXP_SPLIT_TO_TABLE(TAGS, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    CROSS JOIN 
        UNNEST(TagsArray) AS Tags
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)

SELECT 
    RP.Title,
    RP.Body,
    RP.Score,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.OwnerReputation,
    UA.TotalComments,
    UA.TotalUpvotes,
    UA.TotalDownvotes,
    TT.TagName
FROM 
    RankedPosts RP
JOIN 
    UserActivity UA ON RP.OwnerUserId = UA.UserId
JOIN 
    TopTags TT ON TT.TagName = ANY(RP.TagsArray)
WHERE 
    RP.PostRank = 1  -- Get the most recent question for each user
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC;

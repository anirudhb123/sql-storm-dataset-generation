WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS RankByViews
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' 
        AND P.Score > 0
),

PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
    ORDER BY 
        TagCount DESC
),

PostHistoryWithCounts AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) FILTER (WHERE PH.Comment IS NOT NULL) AS CommentCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.OwnerDisplayName,
    PHT.CommentCount,
    COALESCE(PT.TagCount, 0) AS PopularTagCount,
    CASE 
        WHEN RP.RankByViews = 1 THEN 'Top Post'
        WHEN RP.RankByViews <= 3 THEN 'Hot Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts RP
LEFT JOIN 
    PostHistoryWithCounts PHT ON RP.PostId = PHT.PostId
LEFT JOIN 
    PopularTags PT ON PT.TagName IN (SELECT UNNEST(STRING_TO_ARRAY(RP.Title, ' '))) 
WHERE 
    PHT.PostHistoryTypeId IN (1, 4, 10) -- Only interested in certain history types
ORDER BY 
    RP.ViewCount DESC,
    PopularTagCount DESC NULLS LAST
LIMIT 100;

-- Explanation of various constructs:
-- CTEs are used to create ranked posts by views, popular tags based on frequency, and post history counts.
-- Window functions are used for ranking posts.
-- The filter clause and COALESCE handle NULL values and counts efficiently.
-- Use of string expressions to find posts that match popular tags in the title.
-- The case statement provides semantic categorization of posts based on their rank.

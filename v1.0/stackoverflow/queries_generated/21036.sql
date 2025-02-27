WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank,
        COALESCE(P.ClosedDate, 'No Closure') AS ClosureStatus,
        STRING_AGG(T.TagName, ', ') AS TagsList
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON T.WikiPostId = P.Id OR T.ExcerptPostId = P.Id
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.OwnerUserId, P.ClosedDate
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        T.TagsList,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        RP.ClosureStatus
    FROM 
        RankedPosts RP
    LEFT JOIN 
        UserBadges UB ON RP.OwnerUserId = UB.UserId
)
SELECT 
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.TagsList,
    PD.ClosureStatus,
    COALESCE(TS.AvgScore, 0) AS AvgScoreForTag,
    COALESCE(TS.PostCount, 0) AS PostsWithTagCount,
    PD.GoldBadges,
    PD.SilverBadges,
    PD.BronzeBadges
FROM 
    PostDetails PD
LEFT JOIN 
    TagStatistics TS ON PD.TagsList LIKE '%' || TS.TagName || '%'
WHERE 
    PD.ScoreRank = 1
ORDER BY 
    PD.Score DESC, PD.ViewCount DESC NULLS LAST
LIMIT 100
OFFSET 0;

### Explanation of Query Constructs:

1. **Common Table Expressions (CTEs)**: 
   - **RankedPosts**: Ranks posts by score for each user and aggregates tags.
   - **TagStatistics**: Computes statistics for each tag such as average score and count of posts associated with the tag.
   - **UserBadges**: Counts the badges for each user by type (Gold, Silver, Bronze).
   - **PostDetails**: Joins posts with user badge data and aggregates necessary details.

2. **Window Functions**: Used `ROW_NUMBER()` for ranking posts based on score.

3. **String Aggregation**: `STRING_AGG` collects tags for each post into a single string.

4. **LEFT JOINs**: Used throughout to include posts even if they lack tags or user badges.

5. **NULL Logic**: Handled using `COALESCE` to provide default values in case of NULLs (like average score or tag count).

6. **WHERE Clauses**: Apply filters on creations, closure status, and ensure only the top-ranked posts are selected.

7. **Advanced Filtering**: Boolean expressions and LIKE predicates for dynamic filtering based on tags.

8. **Complicated Orderings and Limitations**: Ordered results based on score and view count with offset for pagination. 

This query provides a comprehensive overview of post performance while maintaining a complex structure to test various SQL constructs.

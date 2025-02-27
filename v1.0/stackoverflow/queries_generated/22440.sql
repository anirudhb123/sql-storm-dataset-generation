WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Tags,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (CURRENT_DATE - INTERVAL '30 days')
          AND P.ViewCount > 100
),
UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostActivity AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        MIN(PH.CreationDate) AS FirstClosureDate,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
CommentData AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(C.Text, ' | ' ORDER BY C.CreationDate) AS CommentTexts
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.AnswerCount,
    RP.CommentCount,
    RP.Tags,
    UBS.UserId,
    UBS.BadgeCount,
    UBS.GoldBadges,
    UBS.SilverBadges,
    UBS.BronzeBadges,
    PA.ClosureCount,
    PA.FirstClosureDate,
    PA.LastEditDate,
    CD.CommentCount AS TotalComments,
    COALESCE(CD.CommentTexts, 'No comments yet') AS AllComments,
    COALESCE(UBC.BadgeCount, 0) AS UserBadgeCount
FROM 
    RankedPosts RP
JOIN 
    UserBadgeCounts UBS ON RP.OwnerUserId = UBS.UserId
LEFT JOIN 
    PostActivity PA ON RP.PostId = PA.PostId
LEFT JOIN 
    CommentData CD ON RP.PostId = CD.PostId
WHERE 
    RP.PostRank = 1
ORDER BY 
    RP.Score DESC, RP.ViewCount ASC
LIMIT 100
OFFSET 0;

### Explanation:
- **Common Table Expressions (CTEs)**:
  - `RankedPosts`: Filters and ranks posts based on criteria such as creation date and view count.
  - `UserBadgeCounts`: Computes the number of badges per user and their classifications (Gold, Silver, Bronze).
  - `PostActivity`: Counts how many times the post was closed and tracks the first and last modification dates.
  - `CommentData`: Aggregates comments for each post, counting them and concatenating their texts.

- **Main Query**: 
  - It joins the ranked posts with user badge counts, post activity, and comment data.
  - Uses `COALESCE` to manage potential nulls in the counts and texts.
  - Filters for the highest-ranked posts and sorts by score and view count for performance evaluation.

This query serves as a performance benchmark, due to its complexity and variety of constructs, including window functions, conditional aggregations, and string manipulations.

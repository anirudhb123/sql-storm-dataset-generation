WITH RankedPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.PostTypeId,
        Posts.Score,
        Posts.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY Posts.PostTypeId ORDER BY Posts.Score DESC) AS Rank
    FROM 
        Posts
    WHERE 
        Posts.Score > 0
),
UserBadges AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(Badges.Id) AS BadgeCount,
        SUM(CASE WHEN Badges.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Badges.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Badges.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
),
PostHistoryDetails AS (
    SELECT 
        PostHistory.PostId,
        COUNT(DISTINCT PostHistory.UserId) AS EditCount,
        MAX(PostHistory.CreationDate) AS LastEditDate
    FROM 
        PostHistory
    WHERE 
        PostHistory.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        PostHistory.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.PostTypeId,
    RP.Score,
    RP.Rank,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(UB.GoldBadges, 0) AS UserGoldBadges,
    COALESCE(UB.SilverBadges, 0) AS UserSilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS UserBronzeBadges,
    MAX(PH.LastEditDate) AS MostRecentEdit,
    CASE
        WHEN MAX(PH.LastEditDate) < NOW() - INTERVAL '30 days' THEN 'Old Post'
        ELSE 'Recent Post'
    END AS PostAgeStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    UserBadges UB ON RP.PostId IN (SELECT ID FROM Posts WHERE OwnerUserId = UB.UserId)
LEFT JOIN 
    PostHistoryDetails PH ON RP.PostId = PH.PostId
WHERE 
    RP.Rank <= 5 -- Top 5 posts per type
GROUP BY 
    RP.PostId, RP.Title, RP.PostTypeId, RP.Score, RP.Rank, UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges
ORDER BY 
    RP.Score DESC, RP.Rank;

This SQL query does the following:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Ranks posts by score within their type.
   - `UserBadges`: Calculates the number of badges earned by users, categorized by badge class.
   - `PostHistoryDetails`: Counts the number of edits on posts and finds the most recent edit date.

2. **Main Select Statement**:
   - Gathers data from the three CTEs using appropriate `JOIN` operations.
   - Uses `COALESCE` to handle potential `NULL` values for badge counts.
   - Includes a `CASE` statement to classify posts based on their edit date.
   - Only selects the top 5 ranked posts for further analysis, providing an intriguing performance benchmark.

This combines various SQL constructs such as CTEs, window functions, aggregation, and advanced filtering logic, while also demonstrating complex join operations and conditional logic.

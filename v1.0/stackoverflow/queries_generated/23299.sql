WITH RecentUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        U.Id
),

TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.Score IS NOT NULL AND 
        P.ViewCount IS NOT NULL
),

UserBadgeCount AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.TotalViews,
    UA.UpVotesReceived,
    UA.DownVotesReceived,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(UB.BadgeNames, 'No badges') AS Badges,
    TP.Title AS TopPostTitle,
    TP.ViewCount AS TopPostViews,
    TP.Score AS TopPostScore
FROM 
    RecentUserActivity UA
LEFT JOIN 
    UserBadgeCount UB ON UA.UserId = UB.UserId
LEFT JOIN 
    TopPosts TP ON UA.UserId = (SELECT P.OwnerUserId FROM Posts P WHERE P.Id = TP.PostId LIMIT 1)
WHERE 
    UA.Reputation > 1000
ORDER BY 
    UA.Reputation DESC, 
    UA.TotalViews DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation:
1. **CTEs (Common Table Expressions)**:
   - **RecentUserActivity**: Retrieves the recent activity of users created in the last year, including post counts, total views, and received votes.
   - **TopPosts**: Defines the top posts by score, ordering by most recent for ties.
   - **UserBadgeCount**: Aggregates the count and names of badges received by each user.

2. **Main Query**:
   - Joins recent user activity with badge counts and selects a top post for each user, ensuring that users with a reputation greater than 1000 are included.
   - Uses COALESCE to handle NULL values, replacing them with useful default messages.

3. **Bizarre Semantics**:
   - The final selection retrieves the "TopPost" associated with users in the `RecentUserActivity`, which might yield unexpected results if users don’t have any posts (it defaults to the first row from the `TopPosts` CTE, which could link unrelated posts to users).
   - The use of `LIMIT 1` in the subquery of the join can lead to unintended associations due to potentially returning arbitrary records among multiple possible matches.

This query effectively demonstrates various SQL constructs like CTEs, window functions, and aggregations while incorporating unusual logical handling of potentially related data.

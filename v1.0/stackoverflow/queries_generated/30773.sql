WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserDisplayName,
        U.Reputation,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswers,
        P.CreationDate AS PostCreationDate,
        P.Score AS PostScore,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 

UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Badges B
    WHERE 
        B.Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        B.UserId
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        AVG(P.Score) OVER (PARTITION BY P.OwnerUserId) AS AvgPostScore,
        COUNT(*) AS TotalPosts
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
)

SELECT
    UA.UserId,
    UA.UserDisplayName,
    UA.Reputation,
    UA.AcceptedAnswers,
    UA.PostCreationDate,
    UA.PostScore,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.Badges, 'No badges') AS Badges,
    PS.CommentCount,
    PS.VoteCount,
    PS.AvgPostScore,
    PS.TotalPosts
FROM 
    UserActivity UA
LEFT JOIN 
    UserBadges UB ON UA.UserId = UB.UserId
LEFT JOIN 
    PostStatistics PS ON UA.UserId = PS.OwnerUserId
WHERE 
    UA.ActivityRank <= 10
ORDER BY 
    UA.Reputation DESC,
    UA.PostCreationDate DESC;

This SQL query achieves several objectives by utilizing various SQL constructs:

1. **Recursive CTE** (`UserActivity`):
   - Gathers users who created posts in the last year and ranks their activity based on post creation date.

2. **Aggregate Functions** (`UserBadges`, `PostStatistics`):
   - Collects badge counts and badge names using `COUNT` and `STRING_AGG`.
   - Calculates comment and vote counts for each post along with the average score of the posts authored by each user.

3. **Complex Joins**:
   - Left joins between user activities, badge data, and post statistics to compile a comprehensive report that captures user engagement metrics.

4. **COALESCE for NULL handling**:
   - Ensures that users without badges or posts still display meaningful default output.

5. **Order By**:
   - Orders results primarily by user reputation and then by post creation date to highlight the most active and reputable users first while limiting the results to the top 10 most active users.

This query can serve performance benchmarking against complex joins, aggregations, and recursive logic in SQL.

WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE NULL END) AS AvgViewPerPost,
        EXTRACT(YEAR FROM AGE(u.CreationDate)) AS AccountAgeYears
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        ARRAY_AGG(b.Name) AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS IsAccepted,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(DISTINCT c.Id) 
                  FROM Comments c 
                  WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
)
SELECT 
    um.UserId,
    um.DisplayName,
    um.Reputation,
    um.PostCount,
    um.TotalScore,
    um.TotalViews,
    COALESCE(ub.BadgeNames, '{}') AS BadgeNames,
    ub.BadgeCount,
    SUM(pd.ViewCount) AS OverallPostViews,
    SUM(pd.CommentCount) AS TotalComments,
    COUNT(*) FILTER (WHERE pd.IsAccepted = 'Yes') AS AcceptedPostCount,
    CASE 
        WHEN SUM(pd.ViewCount) > 0 THEN SUM(pd.Score) * 1.0 / SUM(pd.ViewCount) 
        ELSE 0 
    END AS ScorePerView,
    COUNT(*) OVER () AS TotalUsers,
    RANK() OVER (ORDER BY um.Reputation DESC) AS ReputationRank
FROM 
    UserMetrics um
LEFT JOIN 
    UserBadges ub ON um.UserId = ub.UserId
LEFT JOIN 
    PostDetails pd ON um.UserId = pd.OwnerUserId
GROUP BY 
    um.UserId, um.DisplayName, um.Reputation, ub.BadgeNames, ub.BadgeCount
HAVING 
    COUNT(pd.PostId) > 0 -- Only include users with posts
ORDER BY 
    ScorePerView DESC,
    um.Reputation DESC
LIMIT 100;

### Explanation:
- **Common Table Expressions (CTEs)**: We use CTEs to break down the query into manageable parts:
    - `UserMetrics`: Aggregates user statistics including post counts and total scores.
    - `UserBadges`: Aggregates badge information for users.
    - `PostDetails`: Collects essential post details including acceptance status and comment counts.

- **Metrics and Filtering**: The final query pulls together metrics across users and their posts:
    - Filters users with at least one post.
    - Calculates various aggregative metrics including score per view.

- **Advanced SQL Constructs**: 
    - The use of `COALESCE` for null handling, `ARRAY_AGG` for concatenating badge names, and `FILTER` to count accepted posts.
    - `RANK()` window function to assign rankings based on reputation.
    - Incorporation of metrics around comments and views to give a broader picture of user engagement.

- **Handling NULLs**: The query carefully accounts for NULL values using `COALESCE`, thus avoiding potential issues when aggregating.

- **Semantic Quirks**: The query addresses potential edge cases in user metrics, ensuring it only includes relevant users and avoids division by zero with a case statement.

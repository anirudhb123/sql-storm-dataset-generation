WITH UserMetrics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ActiveUsers AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.Reputation,
        ROW_NUMBER() OVER (ORDER BY um.Reputation DESC) AS ReputationRank,
        DENSE_RANK() OVER (PARTITION BY CASE 
                                            WHEN um.QuestionCount > 0 THEN 'Active Questions' 
                                            WHEN um.AnswerCount > 0 THEN 'Active Answers' 
                                            ELSE 'Inactive' 
                                        END 
                                        ORDER BY um.PostCount DESC) AS ActivityRank
    FROM UserMetrics um
    WHERE um.LastPostDate >= NOW() - INTERVAL '1 month'
),
BadgeData AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
FinalMetrics AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.Reputation,
        au.ReputationRank,
        au.ActivityRank,
        COALESCE(bd.BadgeCount, 0) AS BadgeCount,
        COALESCE(bd.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(bd.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(bd.BronzeBadgeCount, 0) AS BronzeBadgeCount
    FROM ActiveUsers au
    LEFT JOIN BadgeData bd ON au.UserId = bd.UserId
)
SELECT
    f.DisplayName,
    f.Reputation,
    f.ReputationRank,
    f.ActivityRank,
    f.BadgeCount,
    f.GoldBadgeCount,
    f.SilverBadgeCount,
    f.BronzeBadgeCount
FROM FinalMetrics f
WHERE f.ReputationRank <= 10
ORDER BY f.Reputation DESC, f.ActivityRank ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

This SQL query does the following:

1. **UserMetrics**: Computes essential metrics for users, including post counts, question counts, answer counts, total bounties, and the date of their last post.
  
2. **ActiveUsers**: Filters active users based on their activity in the last month, assigning ranks based on their reputations and activity categories (questions, answers, or inactive).

3. **BadgeData**: Compiles badge counts for each user including the number of Gold, Silver, and Bronze badges.

4. **FinalMetrics**: Combines active user data with badge data for a comprehensive view of user performance.

5. Finally, the query extracts data from `FinalMetrics`, focusing on the top 10 users by reputation who are most active, ordered by their reputation and activity level.

This query uses CTEs, window functions, and aggregates for a deep dive into user activity on the Stack Overflow platform while ensuring it accounts for edge cases like users with no posts or badges.

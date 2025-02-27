
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewsPerPost
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.Id, t.TagName
    ORDER BY TotalViews DESC
    LIMIT 10
),
UserRankings AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        @rnk1 := IF(@prev_reputation = ua.Reputation, @rnk1, @rnk1 + 1) AS ReputationRank,
        @prev_reputation := ua.Reputation,
        @rnk2 := IF(@prev_views = ua.TotalViews, @rnk2, @rnk2 + 1) AS ViewsRank,
        @prev_views := ua.TotalViews,
        @rnk3 := IF(@prev_posts = ua.PostCount, @rnk3, @rnk3 + 1) AS PostsRank,
        @prev_posts := ua.PostCount
    FROM UserActivity ua
    CROSS JOIN (SELECT @rnk1 := 0, @rnk2 := 0, @rnk3 := 0, @prev_reputation := NULL, @prev_views := NULL, @prev_posts := NULL) r
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    ur.ViewsRank,
    ur.PostsRank,
    tt.TagName,
    tt.TotalViews AS TagTotalViews,
    tt.PostCount AS TagPostCount
FROM UserRankings ur
JOIN TopTags tt ON tt.PostCount > 5  
ORDER BY ur.Reputation DESC, tt.TotalViews DESC;

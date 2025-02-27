
WITH UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(TIMESTAMPDIFF(SECOND, p.CreationDate, COALESCE(p.LastActivityDate, '2024-10-01 12:34:56'))) AS AvgResponseTime,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS AssociatedTags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
               FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                     UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
               WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS t ON t.TagName <> ''
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ProfileSummary AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.Reputation,
        up.TotalPosts,
        up.TotalQuestions,
        up.TotalAnswers,
        up.TotalViews,
        up.TotalUpvotes,
        up.TotalDownvotes,
        up.AvgResponseTime,
        up.AssociatedTags,
        @postRank := IF(@prevPosts = up.TotalPosts, @postRank, @rank := @rank + 1) AS PostRanking,
        @prevPosts := up.TotalPosts,
        @upvoteRank := IF(@prevUpvotes = up.TotalUpvotes, @upvoteRank, @rank2 := @rank2 + 1) AS UpvoteRanking,
        @prevUpvotes := up.TotalUpvotes,
        @reputationRank := IF(@prevReputation = up.Reputation, @reputationRank, @rank3 := @rank3 + 1) AS ReputationRanking,
        @prevReputation := up.Reputation
    FROM UserPerformance up, 
    (SELECT @prevPosts := NULL, @postRank := 0, @prevUpvotes := NULL, @upvoteRank := 0, @prevReputation := NULL, @reputationRank := 0, 
             @rank := 0, @rank2 := 0, @rank3 := 0) r
),
TopProfiles AS (
    SELECT 
        ps.*,
        CASE 
            WHEN ps.PostRanking <= 10 THEN 'Top 10 by Post Count'
            WHEN ps.UpvoteRanking <= 10 THEN 'Top 10 by Upvotes'
            WHEN ps.ReputationRanking <= 10 THEN 'Top 10 by Reputation'
            ELSE 'General User'
        END AS UserCategory
    FROM ProfileSummary ps
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    TotalUpvotes,
    TotalDownvotes,
    AvgResponseTime,
    AssociatedTags,
    UserCategory
FROM TopProfiles
WHERE TotalPosts > 0
ORDER BY Reputation DESC, TotalUpvotes DESC, TotalPosts DESC;

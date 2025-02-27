WITH RECURSIVE UserActivity AS (
    -- Fetch users and their reputation scores along with total post counts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), PostScore AS (
    -- Calculate average post scores per user and rank them
    SELECT 
        UserId,
        AVG(Score) AS AvgPostScore
    FROM 
        Posts
    GROUP BY 
        UserId
), TopUsers AS (
    -- Get top users with their activities
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.TotalPosts,
        ps.AvgPostScore,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS ReputationRank
    FROM 
        UserActivity ua
    JOIN 
        PostScore ps ON ua.UserId = ps.UserId
    WHERE 
        ua.TotalPosts > 10 -- Users with more than 10 posts
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    COALESCE(ps.AvgPostScore, 0) AS AvgPostScore,
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = tu.UserId 
       AND b.Class = 1 -- Count gold badges
    ) AS GoldBadges,
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = tu.UserId 
       AND b.Class IN (2, 3) -- Count silver and bronze badges
    ) AS SilverBronzeBadges,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p ON t.ExcerptPostId = p.Id 
     WHERE p.OwnerUserId = tu.UserId -- Tags from posts by the user
    ) AS UserTags
FROM 
    TopUsers tu
LEFT JOIN 
    Votes v ON tu.UserId = v.UserId -- Joining votes to get voting activity
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.TotalPosts, ps.AvgPostScore
ORDER BY 
    tu.ReputationRank, tu.Reputation DESC;



WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsersPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ubs.TotalBadges, 0) AS TotalBadges,
        COALESCE(aup.TotalPosts, 0) AS TotalPosts,
        COALESCE(aup.Questions, 0) AS Questions,
        COALESCE(aup.Answers, 0) AS Answers,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats ubs ON u.Id = ubs.UserId
    LEFT JOIN 
        ActiveUsersPosts aup ON u.Id = aup.OwnerUserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalBadges,
    up.TotalPosts,
    up.Questions,
    up.Answers,
    up.Reputation,
    @reputationRank := IF(@prevReputation = up.Reputation, @reputationRank, @rankNum) AS ReputationRank,
    @rankNum := @rankNum + 1,
    @prevReputation := up.Reputation,
    @postRank := IF(@prevTotalPosts = up.TotalPosts, @postRank, @postNum) AS PostRank,
    @postNum := @postNum + 1,
    @prevTotalPosts := up.TotalPosts
FROM 
    UserPerformance up,
    (SELECT @reputationRank := 0, @rankNum := 1, @prevReputation := NULL, 
            @postRank := 0, @postNum := 1, @prevTotalPosts := NULL) AS vars
WHERE 
    up.TotalPosts > 0
ORDER BY 
    up.Reputation DESC, 
    up.TotalPosts DESC
LIMIT 10;

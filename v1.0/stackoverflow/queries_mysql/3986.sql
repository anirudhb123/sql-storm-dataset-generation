
WITH UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
), PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner_user_id := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.OwnerUserId
), UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS FastAchieverBadges,
        SUM(pa.UpVotes - pa.DownVotes) AS Score
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostAnalytics pa ON u.Id = pa.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, ub.BadgeCount
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.FastAchieverBadges,
    us.Score,
    GROUP_CONCAT(DISTINCT p.Title SEPARATOR ', ') AS RelatedPosts,
    MAX(pa.CommentCount) AS MaxCommentedPost,
    COUNT(DISTINCT pa.PostId) AS TotalPosts,
    CASE 
        WHEN us.Score > 100 THEN 'High Performer'
        WHEN us.Score > 50 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS PerformanceCategory
FROM 
    UserScores us
LEFT JOIN 
    PostAnalytics pa ON us.UserId = pa.OwnerUserId
LEFT JOIN 
    Posts p ON p.OwnerUserId = us.UserId
WHERE 
    us.Score IS NOT NULL
GROUP BY 
    us.UserId, us.DisplayName, us.FastAchieverBadges, us.Score
HAVING 
    COUNT(pa.PostId) > 5
ORDER BY 
    us.Score DESC
LIMIT 10;

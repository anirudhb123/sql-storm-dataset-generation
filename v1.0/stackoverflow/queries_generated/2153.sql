WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(pr.AvgRating, 0) AS AvgRating,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            AVG(Score) AS AvgRating 
        FROM 
            Votes v 
        JOIN 
            PostHistory ph ON ph.PostId = v.PostId AND v.VoteTypeId = 2 -- Upvote
        GROUP BY 
            PostId
    ) pr ON p.Id = pr.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT rp.Id) AS TotalPosts,
    SUM(CASE WHEN rp.AvgRating > 3 THEN 1 ELSE 0 END) AS HighRatedPosts,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UNNEST(string_to_array(rp.Title, ' ')) AS t(TagName) -- Simulating tag extraction from titles for demonstration
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT rp.Id) > 5
ORDER BY 
    TotalPosts DESC
LIMIT 10;

-- An additional query to retrieve user badges based on their reputation and number of posts
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Class,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
)
SELECT 
    ub.UserId,
    u.DisplayName,
    COUNT(CASE WHEN ub.Class = 1 THEN 1 END) AS GoldBadges,
    COUNT(CASE WHEN ub.Class = 2 THEN 1 END) AS SilverBadges,
    COUNT(CASE WHEN ub.Class = 3 THEN 1 END) AS BronzeBadges
FROM 
    UserBadges ub
JOIN 
    Users u ON ub.UserId = u.Id
WHERE 
    ub.BadgeRank <= 3 
GROUP BY 
    ub.UserId, u.DisplayName
ORDER BY 
    GoldBadges DESC, SilverBadges DESC, BronzeBadges DESC
LIMIT 5;

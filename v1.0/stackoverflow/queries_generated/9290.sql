WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(b.Class) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    WHERE PostTypeId = 1
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 10
),
UserSummary AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.TotalPosts,
        ur.TotalComments,
        ur.TotalBadges,
        pt.TagName
    FROM UserReputation ur
    LEFT JOIN PopularTags pt ON ur.TotalPosts > 0
)
SELECT 
    us.UserId,
    us.Reputation,
    us.TotalPosts,
    us.TotalComments,
    us.TotalBadges,
    STRING_AGG(DISTINCT us.TagName, ', ') AS PopularTags
FROM UserSummary us
GROUP BY us.UserId, us.Reputation, us.TotalPosts, us.TotalComments, us.TotalBadges
ORDER BY us.Reputation DESC
LIMIT 20;

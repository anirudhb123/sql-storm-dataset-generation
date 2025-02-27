WITH RankedBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Class,
        ROW_NUMBER() OVER(PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM Badges b
    WHERE b.Class = 1 -- Only Gold badges
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS TotalUpVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) / 3600.0) AS AvgPostAgeInHours
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
), ActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(c.Score), 0) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PopularityRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBounty,
    us.TotalUpVotes,
    us.TotalPosts,
    us.AvgPostAgeInHours,
    rb.BadgeName AS TopBadge,
    COALESCE(ap.Title, 'No Posts') AS MostPopularPost,
    COALESCE(ap.TotalScore, 0) AS PostScore,
    COALESCE(ap.CommentCount, 0) AS PostCommentCount
FROM UserStats us
LEFT JOIN RankedBadges rb ON us.UserId = rb.UserId AND rb.BadgeRank = 1
LEFT JOIN ActivePosts ap ON us.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = ap.Id)
WHERE us.TotalPosts > 0
ORDER BY us.TotalBounty DESC, us.TotalUpVotes DESC, us.AvgPostAgeInHours ASC
LIMIT 100;


WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT a.Id) AS TotalAnswers,
        SUM(vt.VoteTypeId = 2) AS TotalUpvotes,
        SUM(vt.VoteTypeId = 3) AS TotalDownvotes,
        AVG(DATEDIFF(DAY, p.CreationDate, GETDATE())) AS AvgPostAgeDays
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN Votes vt ON p.Id = vt.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),

TopBadges AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM Users u
    INNER JOIN Badges b ON u.Id = b.UserId
    WHERE b.Class = 1 -- Gold badges
    GROUP BY u.Id
),

PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN STRING_SPLIT(p.Tags, '<>') t ON t.value IS NOT NULL
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalAnswers,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.AvgPostAgeDays,
    tb.Badges,
    pts.PostId,
    pts.Title,
    pts.Tags,
    pts.Score,
    pts.ViewCount
FROM UserStats us
LEFT JOIN TopBadges tb ON us.UserId = tb.UserId
LEFT JOIN PostTagStats pts ON us.UserId = pts.OwnerUserId
WHERE us.TotalPosts > 0
ORDER BY us.Reputation DESC, us.TotalPosts DESC, pts.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;

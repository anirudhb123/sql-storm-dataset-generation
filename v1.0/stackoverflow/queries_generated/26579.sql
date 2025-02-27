WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    JOIN Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE p.Score > 10
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalComments,
    us.TotalBadges,
    us.TotalUpvotes,
    us.TotalDownvotes,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViewCount,
    php.EditCount AS PostEditCount,
    php.LastEdited AS PostLastEdited,
    php.HistoryTypes AS PostHistoryTypes,
    pp.Tags AS PostTags
FROM UserStats us
JOIN PostHistoryStats php ON us.UserId = php.PostId
JOIN PopularPosts pp ON php.PostId = pp.PostId
ORDER BY us.Reputation DESC, pp.Score DESC;

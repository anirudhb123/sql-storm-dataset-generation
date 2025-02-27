WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(b.Class), 0) DESC) AS BadgeRank,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),
PostRankings AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- 10 = Post Closed, 11 = Post Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalBadges,
    us.TotalPosts,
    us.BadgeRank,
    COALESCE(cps.CloseCount, 0) AS TotalCloseActions,
    COALESCE(cps.LastCloseDate, 'Never') AS LastClosedDate,
    pr.Title AS MostPopularPost,
    pr.Score,
    pr.ViewCount,
    (SELECT AVG(ViewCount) FROM Posts) AS AveragePostViews,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    UserStatistics us
LEFT JOIN 
    ClosedPostStats cps ON us.UserId = cps.PostId -- Relationship via post association
LEFT JOIN 
    PostRankings pr ON us.UserId = pr.PostRank AND pr.PostRank = 1 -- Get the most popular post for the user
LEFT JOIN 
    Posts p ON us.UserId = p.OwnerUserId -- Join for tags aggregation
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) as t(TagName) ON t.TagName IS NOT NULL 
WHERE 
    us.Reputation > (SELECT AVG(Reputation) FROM Users) -- Only include users above average reputation
GROUP BY 
    us.DisplayName, us.Reputation, us.TotalBadges, us.TotalPosts, us.BadgeRank, 
    pr.Title, pr.Score, pr.ViewCount
ORDER BY 
    us.TotalPosts DESC, us.TotalBadges DESC;

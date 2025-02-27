WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(co.FavoriteCount, 0) AS FavoriteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS FavoriteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 5  -- assuming 5 is for 'favorite'
        GROUP BY 
            PostId
    ) co ON p.Id = co.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.FavoriteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5  -- Get top 5 posts per user
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(fp.CommentCount) AS TotalComments,
        SUM(fp.FavoriteCount) AS TotalFavorites,
        COUNT(fp.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        FilteredPosts fp ON u.Id = fp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        SUM(fp.CommentCount) > 10 OR 
        SUM(fp.FavoriteCount) > 10       -- Filter for users with significant engagement
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalComments,
    us.TotalFavorites,
    us.TotalPosts,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    UserStatistics us
LEFT JOIN 
    Votes v ON us.UserId = v.UserId
WHERE 
    v.CreationDate >= NOW() - INTERVAL '6 months'  -- Bounty contributions in the last 6 months
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.TotalComments, us.TotalFavorites, us.TotalPosts
ORDER BY 
    us.Reputation DESC, us.TotalFavorites DESC
LIMIT 10;

-- Commenting on the query potential corner cases:
-- 1. Users with no posts will still end up in UserStatistics due to LEFT JOIN, thus showing zero counts.
-- 2. Handling NULL values through COALESCE is essential in rankings to avoid skewing logic.
-- 3. The HAVING clause may filter out users with significant reputation but no posts if their engaged posts do not meet the criteria.
-- 4. By including the BountyInfo, we iterate the relationships across multiple tables, showcasing complex joining logic.

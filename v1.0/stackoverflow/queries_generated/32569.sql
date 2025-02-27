WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')  -- Only consider posts from the last year
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LatestBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.LatestBadgeDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    INNER JOIN 
        UsersWithBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation >= 1000  -- Only users with a reputation of at least 1000
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    pp.Title AS TopPostTitle,
    pp.Score AS TopPostScore,
    pp.ViewCount AS TopPostViews,
    pp.CreationDate AS TopPostCreation,
    ph.PostHistoryTypeId,
    ph.CreationDate AS PostHistoryCreationDate,
    ph.UserDisplayName AS EditorDisplayName,
    ph.Comment AS EditorComment,
    ph.Text AS PostHistoryText
FROM 
    TopUsers up
JOIN 
    RankedPosts pp ON up.UserId = pp.OwnerUserId AND pp.rank = 1  -- Get the top posts for each user
LEFT JOIN 
    PostHistory ph ON pp.PostId = ph.PostId AND 
                     ph.CreationDate = (SELECT MAX(CreationDate) 
                                        FROM PostHistory 
                                        WHERE PostId = pp.PostId)  -- Get the latest history record for each post
WHERE 
    up.ReputationRank <= 10  -- Limit to top 10 users
ORDER BY 
    up.Reputation DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ActiveUsers AS (
    SELECT
        u.UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(rp.PostId, 0) AS TopPostId,
        rp.Title AS TopPostTitle,
        rp.Score AS TopPostScore
    FROM 
        UserStats u
    LEFT JOIN 
        RankedPosts rp ON u.UserId = rp.PostId
    WHERE 
        u.TotalPosts > 5 AND u.Reputation > 100
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.Reputation,
    au.TopPostTitle,
    COALESCE(au.TopPostScore, 0) AS ScoreOfTopPost,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END) AS HistoryChanges,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryTypes
FROM 
    ActiveUsers au
LEFT JOIN 
    Comments c ON au.TopPostId = c.PostId
LEFT JOIN 
    PostHistory ph ON au.TopPostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
WHERE 
    au.TopPostScore IS NOT NULL OR au.Reputation > 200
GROUP BY 
    au.UserId, au.DisplayName, au.Reputation, au.TopPostTitle
ORDER BY 
    au.Reputation DESC, ScoreOfTopPost DESC
LIMIT 25 OFFSET 0;

This query performs the following functionalities:
1. It calculates a ranking for questions based on their scores and creation dates.
2. It summarizes user statistics including the total count of posts, count of positive posts, and associated badges.
3. Filters for active users who have made more than 5 posts and have a reputation of over 100.
4. Collects additional statistics from comments and post history for these active users.
5. Groups results and aggregates the types of post history encountered, showing comprehensive results for further analysis.

WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserRanked AS (
    SELECT
        UserId,
        DisplayName,
        TotalBountyAmount,
        UpVoteCount,
        DownVoteCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        PostCount,
        RANK() OVER (ORDER BY TotalBountyAmount DESC, UpVoteCount DESC) AS UserRank
    FROM 
        UserScores
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL '30 days') 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
PopularPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.ViewCount DESC) AS PopularityRank
    FROM 
        PostDetails pd
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.TotalBountyAmount,
    ur.UpVoteCount,
    ur.DownVoteCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ur.PostCount,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.CommentCount,
    pp.PopularityRank
FROM 
    UserRanked ur
LEFT JOIN 
    PopularPosts pp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = (SELECT MIN(PostId) FROM Posts WHERE CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days')))
WHERE 
    ur.UserRank <= 10
ORDER BY 
    ur.UserRank, pp.PopularityRank 
LIMIT 50;

-- Explanation of Edge Cases and Construct Usage:
-- 1. CTEs are used to break down the query into logical parts, improving readability and maintainability.
-- 2. The UserRanked CTE employs a ranking function to create a ranking system based on multiple metrics.
-- 3. Outer joins accommodate the possibility of users without votes or posts without comments.
-- 4. The correlated subquery is used in selecting a specific post for each user based on the minimum PostId for recent posts.
-- 5. Conditional aggregations in UserScores calculate counts based on different criteria, showcasing how NULL values can be handled gracefully.
-- 6. The main query applies limiting along with ordering by user ranks and post popularity, demonstrating combined logic over different datasets.

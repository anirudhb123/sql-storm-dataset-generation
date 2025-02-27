WITH RecursivePostHierarchy AS (
    -- Common Table Expression to get hierarchy of posts and their replies
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        CreationDate,
        Score,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON r.PostId = p.ParentId
),
UserReputation AS (
    -- CTE to get user reputation over the last year
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    -- CTE to get details of posts that have been closed
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
),
PopularTags AS (
    -- CTE to get most popular tags
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
UserBadges AS (
    -- CTE to get user badges with ranking
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges, 
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges, 
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    u.DisplayName,
    up.TotalPosts,
    up.TotalScore,
    up.ReputationRank,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ct.PostId AS ClosedPostId,
    ct.Title AS ClosedPostTitle,
    ct.CloseReason,
    pt.TagName AS PopularTag
FROM 
    UserReputation up
JOIN 
    Users u ON up.UserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    ClosedPosts ct ON ct.Comment IS NOT NULL -- only include users who have closed posts
LEFT JOIN 
    PopularTags pt ON pt.PostCount > 5
WHERE 
    up.ReputationRank <= 10 -- Top 10 users
ORDER BY 
    up.TotalScore DESC, 
    up.TotalPosts DESC;

-- Final selection includes user info, closed posts, and popular tags

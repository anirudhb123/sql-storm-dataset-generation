WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScorePosts,
        COALESCE(AVG(p.Score), 0) AS AvgScore,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag ON TRUE -- Assuming split is done correctly
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.OwnerUserId
),
CommentStats AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(c.Score), 0) AS CommentScore
    FROM 
        Comments c
    GROUP BY 
        c.UserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
FinalStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.PositiveScorePosts, 0) AS PositiveScorePosts,
        COALESCE(ps.AvgScore, 0) AS AvgScore,
        COALESCE(cs.TotalComments, 0) AS TotalComments,
        COALESCE(cs.CommentScore, 0) AS CommentScore,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.HighestBadgeClass, 0) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON ps.OwnerUserId = u.Id
    LEFT JOIN 
        CommentStats cs ON cs.UserId = u.Id
    LEFT JOIN 
        UserBadges ub ON ub.UserId = u.Id
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.TotalPosts,
    f.PositiveScorePosts,
    f.AvgScore,
    f.TotalComments,
    f.CommentScore,
    f.BadgeCount,
    f.HighestBadgeClass,
    CASE 
        WHEN f.BadgeCount > 5 THEN 'Expert'
        WHEN f.TotalPosts > 10 AND f.PositiveScorePosts > 5 THEN 'Active Contributor'
        ELSE 'Newcomer'
    END AS ContributorLevel
FROM 
    FinalStats f
WHERE 
    f.TotalPosts > 0
ORDER BY 
    f.TotalPosts DESC, f.AvgScore DESC
LIMIT 100;

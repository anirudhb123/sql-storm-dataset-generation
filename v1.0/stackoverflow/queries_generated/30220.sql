WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY Score DESC) AS AnswerRank
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Focus on questions
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.ParentId ORDER BY p.Score DESC) AS AnswerRank
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
    WHERE 
        p.PostTypeId = 2  -- Joining answers
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostsWithMeta AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ph.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(CASE WHEN p.ClosedDate IS NOT NULL THEN 'Closed' ELSE 'Active' END, 'Unknown') AS PostStatus
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
)
SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    p.OwnerDisplayName,
    p.PostStatus,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PostRank,
    p2.ViewCount AS ParentViewCount
FROM 
    PostsWithMeta p
LEFT JOIN 
    RecursivePostHierarchy r ON p.PostId = r.ParentId
LEFT JOIN 
    UserWithBadges u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostsWithMeta p2 ON p.ParentId = p2.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter for recent posts
    AND (p.Score > 0 OR p.ViewCount > 100)  -- Posts with score or view count
    AND p.PostStatus = 'Active'
    AND (u.TotalBadges IS NULL OR u.TotalBadges > 2)  -- Users with more than 2 badges
ORDER BY 
    p.Score DESC,
    p.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;  -- Retrieve the top 10 posts

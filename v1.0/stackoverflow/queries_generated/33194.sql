WITH RecursivePostCTE AS (
    -- Recursive CTE to find all child posts for a given post
    SELECT 
        Id, 
        ParentId, 
        CreationDate, 
        Score, 
        OwnerUserId
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Start with top-level posts

    UNION ALL

    SELECT 
        p.Id, 
        p.ParentId, 
        p.CreationDate, 
        p.Score, 
        p.OwnerUserId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.Id   -- Join with the CTE to find children
),
RankedPosts AS (
    -- CTE to rank posts based on their score and view count
    SELECT 
        p.Id,
        p.Title, 
        p.Score, 
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
)
SELECT 
    u.DisplayName AS User,
    COUNT(DISTINCT pp.Id) AS PostCount,
    SUM(pp.Score) AS TotalScore,
    AVG(pp.ViewCount) AS AverageViews,
    MAX(h.CreationDate) AS LastActivity,
    COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
    COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
    COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagNames,
    COUNT(DISTINCT rp.Id) AS ChildPostCount
FROM 
    Users u
LEFT JOIN 
    Posts pp ON pp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Tags t ON pp.Tags LIKE CONCAT('%', t.TagName, '%')  -- Find tags associated with the posts
LEFT JOIN 
    RecursivePostCTE rp ON pp.Id = rp.ParentId  -- Count child posts
LEFT JOIN 
    PostHistory h ON h.PostId = pp.Id
WHERE 
    u.Reputation > 1000  -- Filter users with reputation above 1000
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT pp.Id) > 10  -- Only users with more than 10 posts
ORDER BY 
    TotalScore DESC, 
    PostCount DESC;

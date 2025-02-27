WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankViews,
        COALESCE((SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT SUM(b.Class) FROM Badges b WHERE b.UserId = p.OwnerUserId), 0) AS OwnerBadges
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankScore <= 5 THEN 'Top'
            WHEN rp.RankViews <= 10 THEN 'Trendy'
            ELSE 'Other'
        END AS PostTypeCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.AnswerCount > 0 OR rp.CommentCount > 3
),
PostAggregates AS (
    SELECT 
        p.PTypeCategory,
        COUNT(DISTINCT p.PostId) AS TotalPosts,
        SUM(p.OwnerBadges) AS TotalBadges,
        AVG(p.Score) AS AverageScore
    FROM 
        FilteredPosts p
    GROUP BY 
        p.PostTypeCategory
)
SELECT 
    p.PTypeCategory,
    p.TotalPosts,
    p.TotalBadges,
    p.AverageScore,
    CASE 
        WHEN p.TotalPosts > 10 THEN 'Active Category'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    PostAggregates p
WHERE 
    p.TotalBadges > 5 AND p.AverageScore > 2
ORDER BY 
    p.TotalPosts DESC, p.AverageScore DESC
LIMIT 10;

-- Include unique identifiers for posts that receive links indicating duplicates or are closely related.
SELECT 
    p.Id AS MainPostId,
    p.Title AS MainPostTitle,
    pl.RelatedPostId,
    rp.Title AS RelatedPostTitle,
    CASE 
        WHEN pl.LinkTypeId = 1 THEN 'Linked'
        WHEN pl.LinkTypeId = 3 THEN 'Duplicate'
        ELSE 'Unknown Link Type'
    END AS LinkTypeDescription
FROM 
    Posts p
JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Posts rp ON pl.RelatedPostId = rp.Id
WHERE 
    p.CreationDate < (NOW() - INTERVAL '2 months')
    AND rp.Id IS NULL OR p.Id NOT IN (SELECT DISTINCT pl.PostId FROM PostLinks pl WHERE pl.RelatedPostId IS NOT NULL)
ORDER BY 
    p.Score DESC, p.Title
LIMIT 20;

-- Find users with the most upvotes who have not received any badges as a strange case
SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
    COUNT(b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id
HAVING 
    BadgeCount = 0
    AND TotalUpvotes > 100
ORDER BY 
    TotalUpvotes DESC
LIMIT 15;

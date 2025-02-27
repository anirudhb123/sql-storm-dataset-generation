WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    AVG(rp.Score) AS AverageScore,
    CASE 
        WHEN AVG(rp.ViewCount) IS NOT NULL THEN AVG(rp.ViewCount) 
        ELSE 0 END AS AverageViews,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed,
    MAX(b.Date) FILTER (WHERE b.Class = 1) AS GoldBadgeDate -- Gold badge date
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank <= 5
LEFT JOIN 
    Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (1, 2) -- Only accepted and upvoted
LEFT JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
LEFT JOIN 
    Tags t ON t.Id = pl.RelatedPostId 
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id,
    u.DisplayName,
    u.Reputation
ORDER BY 
    TotalPosts DESC,
    Reputation DESC
LIMIT 10 OFFSET 5;

WITH CloseReasonStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseCount,
        MIN(ph.CreationDate) AS FirstCloseTimestamp,
        MAX(ph.CreationDate) AS LastCloseTimestamp
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Close post
    GROUP BY 
        ph.UserId
)

SELECT 
    u.DisplayName,
    cr.CloseCount,
    cr.FirstCloseTimestamp,
    cr.LastCloseTimestamp,
    CASE 
        WHEN cr.CloseCount > 10 THEN 'Frequent Closures'
        ELSE 'Infrequent Closures'
    END AS ClosureFrequency,
    CASE 
        WHEN COUNT(DISTINCT post.Id) = 0 THEN 'No posts'
        ELSE MAX(post.Title)
    END AS LastPostClosedTitle
FROM 
    CloseReasonStats cr
JOIN 
    Users u ON cr.UserId = u.Id
LEFT JOIN 
    Posts post ON post.OwnerUserId = cr.UserId 
                AND post.PostTypeId = 1 -- Questions
                AND post.CreationDate BETWEEN cr.FirstCloseTimestamp AND cr.LastCloseTimestamp
GROUP BY 
    u.DisplayName, cr.CloseCount, cr.FirstCloseTimestamp, cr.LastCloseTimestamp
HAVING 
    MAX(cr.CloseCount) > 0
ORDER BY 
    cr.CloseCount DESC
LIMIT 5;

SELECT DISTINCT 
    p.Title,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags,
    t.Count AS TagUsageCount,
    ph.Comment AS PostCloseComment
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 -- Closed posts
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON t.Id = pl.RelatedPostId
WHERE 
    ph.Comment IS NOT NULL AND 
    p.CreationDate < '2020-01-01' 
GROUP BY 
    p.Title, t.Count, ph.Comment
HAVING 
    COUNT(DISTINCT t.TagName) > 2
ORDER BY 
    TagUsageCount DESC
LIMIT 10;

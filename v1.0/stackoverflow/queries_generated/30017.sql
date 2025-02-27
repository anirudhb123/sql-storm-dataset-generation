WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        Score,
        OwnerUserId,
        CAST(Title AS VARCHAR(300)) AS FullTitle
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
        p.OwnerUserId,
        CAST(r.FullTitle || ' >> ' || p.Title AS VARCHAR(300)) AS FullTitle
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
)
SELECT 
    u.DisplayName AS User,
    COUNT(DISTINCT p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) AS TotalViews,
    MAX(p.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(CASE WHEN nh.Comment IS NOT NULL THEN 1 ELSE 0 END) AS Comments,
    SUM(v.BountyAmount) AS TotalBounty,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Tags T ON p.Tags LIKE '%' || T.TagName || '%'
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Comments nh ON p.Id = nh.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Up and Down Votes
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    AverageScore DESC;


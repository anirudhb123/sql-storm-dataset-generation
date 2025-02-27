WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.Views,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.Tags FROM '[^<]*') ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Filtering only questions 
        AND p.Score > 0  -- Only include positively scored posts
),
RecentActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.CreationDate >= NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentPostsCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) >= 5  -- Users must have at least 5 posts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Body,
    rp.OwnerDisplayName,
    rp.Views,
    rau.DisplayName AS ActiveUser,
    rau.RecentPostsCount
FROM 
    RankedPosts rp
JOIN 
    RecentActiveUsers rau ON rp.OwnerDisplayName = rau.DisplayName
WHERE 
    rp.RN <= 3  -- Top 3 recent questions per tag
ORDER BY 
    rp.Views DESC,  -- Order by views descending
    rp.CreationDate DESC  -- Then by creation date
LIMIT 100;  -- Limit the results to the top 100 entries

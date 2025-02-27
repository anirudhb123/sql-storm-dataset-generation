WITH RecursiveTags AS (
    SELECT Id, TagName, Count
    FROM Tags
    WHERE Count > 100
    UNION ALL
    SELECT t.Id, t.TagName, t.Count
    FROM Tags t
    INNER JOIN RecursiveTags rt ON t.Count >= rt.Count
),
PopularPosts AS (
    SELECT p.Id, p.Title, p.ViewCount, p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) as Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
      AND p.OwnerUserId IS NOT NULL
),
UserReputation AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties, 
           SUM(u.UpVotes - u.DownVotes) AS Score
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    u.TotalBounties,
    u.Score,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    STRING_AGG(DISTINCT rt.TagName, ', ') AS PopularTags,
    AVG(p.ViewCount) AS AvgViewCount,
    SUM(COALESCE(ph.UserId, 0)) AS EditCount,
    MAX(p.LastActivityDate) AS LastPostActivity
FROM UserReputation u
LEFT JOIN PopularPosts p ON u.UserId = p.OwnerUserId
LEFT JOIN PostsHistory ph ON p.Id = ph.PostId
LEFT JOIN RecursiveTags rt ON p.Tags ILIKE '%' || rt.TagName || '%'
WHERE u.Score > 100
GROUP BY u.DisplayName, u.TotalBounties, u.Score
HAVING COUNT(DISTINCT p.Id) > 5
ORDER BY AvgViewCount DESC
LIMIT 10;

-- Note: This query benchmarks the performance by joining several tables
-- and using CTEs to filter and aggregate data based on criteria such as user reputation, 
-- popular tags, and active posts, while aiming for optimal performance with careful indexing.

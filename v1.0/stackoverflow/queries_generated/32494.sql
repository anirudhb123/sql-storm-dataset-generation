WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ParentId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ParentId,
        rp.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId
)

SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    AVG(p.ViewCount) AS AvgViews,
    MAX(p.CreationDate) AS LatestPost,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList,
    COUNT(DISTINCT COALESCE(b.Id, NULL)) AS TotalBadges,
    DENSE_RANK() OVER (ORDER BY SUM(p.Score) DESC) AS ScoreRank,
    CASE 
        WHEN COUNT(DISTINCT p.Id) > 10 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '<>'))::int)
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id
HAVING 
    SUM(p.Score) > 50
ORDER BY 
    TotalScore DESC;

### Explanation:
- **Recursive CTE**: The `RecursivePosts` CTE retrieves questions and their corresponding answers recursively.
- **Aggregate Functions**: The main `SELECT` combines data from users, their posts, and tags, calculating totals and averages.
- **CASE Statement**: Assigns a contributor status based on the number of posts.
- **LEFT JOINs**: Fetch additional related data (badges and tags) that might not exist.
- **STRING_AGG**: Collects tags into a single string for each user.
- **DENSE_RANK**: Ranks users by their total score.
- **HAVING Clause**: Filters users based on their activity and score.
- **COALESCE**: Used to handle potential NULL values from join operations.

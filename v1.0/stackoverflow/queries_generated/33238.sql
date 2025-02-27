WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        CAST(0 AS INT) AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts parent ON p.ParentId = parent.Id
    WHERE 
        parent.PostTypeId = 1
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
    AVG(p.ViewCount) AS AvgViews,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed,
    MAX(p.CreationDate) AS LastPostDate,
    CASE 
        WHEN AVG(p.ViewCount) > 100 THEN 'High Engagement'
        WHEN AVG(p.ViewCount) BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    COUNT(DISTINCT CASE WHEN p.ClosedDate IS NOT NULL THEN p.Id END) AS ClosedPosts,
    COUNT(DISTINCT CASE WHEN EXISTS (
        SELECT 1 
        FROM PostHistory ph 
        WHERE ph.PostId = p.Id 
        AND ph.PostHistoryTypeId = 10 -- closed posts
    ) THEN p.Id END) AS ConfirmedClosedPosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
LEFT JOIN 
    RecursiveCTE rcte ON rcte.PostId = p.Id
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- only users with more than 5 posts
ORDER BY 
    TotalPosts DESC
LIMIT 10;

This query does the following:
- Uses a recursive CTE to traverse posts, looking for relationships between questions and their answers.
- Aggregates user statistics such as total posts, badge classes, average views, tags used, closed posts, and engagement levels.
- Applies conditional logic to classify engagement levels based on average view counts.
- Filters out users with fewer than 5 posts.
- Sorts users by total posts and limits the output to the top 10 users.

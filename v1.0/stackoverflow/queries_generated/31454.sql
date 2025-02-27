WITH RecursiveTagUsage AS (
    -- CTE to find the usage of tags within posts, filtering out low-usage tags
    SELECT 
        Tags.TagName, 
        COUNT(Posts.Id) AS UsageCount
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '::int'))::int[]
    GROUP BY 
        Tags.TagName
    HAVING 
        COUNT(Posts.Id) > 100 -- Consider tags used in more than 100 posts
),
RecentPosts AS (
    -- CTE to get recent posts with their accepted answers and higher scores
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        COALESCE(a.Title, 'No Accepted Answer') AS AcceptedAnswerTitle
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 month' -- Get posts created in the last month
),
UserStats AS (
    -- CTE to calculate user reputation filtered by active recent posts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(v.BountyAmount, 0)) DESC) AS Ranking
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty start or close
    WHERE 
        p.CreationDate > NOW() - INTERVAL '6 months'
    GROUP BY 
        u.Id
),
FilteredUsers AS (
    -- CTE to filter users with significant contributions 
    SELECT 
        UserId, 
        DisplayName, 
        TotalBounty
    FROM 
        UserStats
    WHERE 
        TotalBounty > 0
)
-- Final query to compile results from the CTEs
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.AcceptedAnswerTitle,
    t.TagName,
    u.DisplayName AS Contributor,
    u.TotalBounty
FROM 
    RecentPosts r
JOIN 
    RecursiveTagUsage t ON r.Title ILIKE '%' || t.TagName || '%' -- Case-insensitive match for tags in titles
LEFT JOIN 
    FilteredUsers u ON u.UserId = r.AcceptedAnswerId
WHERE 
    r.Score > 10 -- Only include posts with a score greater than 10
ORDER BY 
    r.CreationDate DESC, t.UsageCount DESC; -- Order by most recent and popular tags

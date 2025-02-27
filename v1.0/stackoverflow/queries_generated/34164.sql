WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- starting with questions

    UNION ALL

    SELECT 
        p.Id,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts a ON a.AcceptedAnswerId = p.Id
    WHERE 
        Level < 5  -- limiting to depth of 5 for performance
)

SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS NumberOfPosts,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    MAX(p.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    CASE 
        WHEN COUNT(DISTINCT b.Id) > 0 THEN 'Yes'
        ELSE 'No'
    END AS HasBadges,
    COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' END), 'Open') AS PostStatus,
    COUNT(DISTINCT c.Id) AS NumberOfComments

FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Tags t ON t.Id IN (SELECT DISTINCT UNNEST(string_to_array(p.Tags, ',')) FROM Posts)
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    u.Reputation > 1000  -- Filter for experienced users
    AND EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2)  -- only with upvotes
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 0  -- Users must have at least one post
ORDER BY 
    NumberOfPosts DESC, TotalViews ASC
LIMIT 10;

-- CTE for additional insights into post types
WITH PostTypesCount AS (
    SELECT 
        OwnerUserId,
        PostTypeId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId, PostTypeId
)

SELECT 
    u.DisplayName,
    pt.PostTypeId,
    pt.PostCount,
    p.Title,
    p.CreationDate
FROM 
    PostTypesCount pt
JOIN 
    Users u ON u.Id = pt.OwnerUserId
JOIN 
    Posts p ON p.OwnerUserId = u.Id
WHERE 
    pt.PostCount > 5
ORDER BY 
    u.DisplayName, pt.PostTypeId;


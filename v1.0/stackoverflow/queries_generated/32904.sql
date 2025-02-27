WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > DATEADD(MONTH, -3, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS Rank
    FROM 
        UserReputation ur
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    c.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    ur.Reputation,
    ur.BadgeCount,
    COALESCE(COUNT(ph.Id), 0) AS EditHistoryCount,
    CASE 
        WHEN pp.ParentId IS NULL THEN 'Top Level Post' 
        ELSE 'Nested Post' 
    END AS PostType,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (
         SELECT CAST(value AS INT) 
         FROM STRING_SPLIT(pp.Tags, ',')
     )) AS AssociatedTags
FROM 
    Posts pp
LEFT JOIN 
    RecentPosts c ON pp.Id = c.PostId
LEFT JOIN 
    Users u ON pp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON pp.Id = ph.PostId
JOIN 
    TopUsers ur ON u.Id = ur.UserId
WHERE 
    ur.Rank <= 10
GROUP BY 
    pp.PostId, pp.Title, pp.CreationDate, c.CommentCount, u.DisplayName, ur.Reputation, ur.BadgeCount
ORDER BY 
    pp.CreationDate DESC;

This query performs the following operations: 
- It recursively fetches a hierarchy of posts with their levels.
- It retrieves recent posts along with their comment counts.
- It calculates the user reputations and badge counts.
- It selects the top users based on their reputation and aggregates post details along with associated tags.
- It uses string aggregation to list tags in a single field and displays categorization for each post type. 
- The query also considers post edit history and outputs results sorted by the creation date.
